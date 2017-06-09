defmodule KanjiFrequency.PageSourceParser do
  use GenServer
  alias KanjiFrequency.{UrlProcessor, Histogram}

  @interval_range 4000..10_000

  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    schedule_parsing()
    IO.puts "#{__MODULE__} initialized"

    {:ok, nil}
  end

  def handle_info(:parse_page_source, _) do
    UrlProcessor.fetch_page_source()
    |> parse()

    schedule_parsing()

    {:noreply, nil}
  end

  defp parse(nil) do
    IO.puts "No page source received"
    schedule_parsing()
  end

  defp parse(page_source) do
    # Redirect new urls back to UrlProcessor
    Floki.find(page_source, "a")
    |> Enum.flat_map(&(Floki.attribute(&1, "href")))
    |> Enum.filter(&(ValidUrl.validate(&1)))
    |> Enum.reject(&(String.match?(&1, ~r/\*/)))
    |> UrlProcessor.add_urls()

    # Send scrubbed text to Histogram
    Regex.replace(~r/[^\p{Han}]/u, page_source, "")
    |> Histogram.record()
  end

  defp schedule_parsing do
    Process.send_after(self(), :parse_page_source, Enum.random(@interval_range))
  end
end
