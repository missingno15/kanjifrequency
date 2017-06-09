defmodule KanjiFrequency.UrlProcessor do
  @moduledoc """
  Module responsible for sending urls and passing down
  raw page source to TextScrubber.
  """

  use GenServer
  @initial_url "https://www.yahoo.co.jp"
  @http_timeout 15_000

  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    {:ok, response} = HTTPoison.get(@initial_url)

    urls = Floki.find(response.body, "a")
           |> Enum.flat_map(&(Floki.attribute(&1, "href")))
           |> Enum.filter(&(ValidUrl.validate(&1)))
           |> Enum.reject(&(String.match?(&1, ~r/\*/))) # remove weird urls with asterisks

    IO.puts "#{__MODULE__} initialized"

    {:ok, urls}
  end

  ### Client

  def add_urls(new_urls) do
    GenServer.cast(__MODULE__, {:add_urls, new_urls})
  end


  def fetch_page_source do
    GenServer.call(__MODULE__, :fetch_page_source, @http_timeout)
  end

  ### Server callbacks

  def handle_call(:fetch_page_source, _from, state) when length(state) > 1 do
    [url | tail] = state

    case HTTPoison.get(url) do
      {:error, %HTTPoison.Error{}} ->
        IO.puts url
        {:reply, nil, tail}
      {:ok, response} ->
        {:reply, response.body, tail}
    end
  end

  def handle_call(:fetch_page_source, _from, state) do
    {:reply, nil, state}
  end

  def handle_cast({:add_urls, new_urls}, state) do
    {:noreply, recursive_reduce(state, new_urls)}
  end

  defp recursive_reduce(list, []), do: list
  defp recursive_reduce(list, data) do
    [head | tail] = data
    recursive_reduce([head | list], tail)
  end
end
