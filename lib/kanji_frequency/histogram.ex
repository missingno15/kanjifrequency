defmodule KanjiFrequency.Histogram do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(empty_histogram) do
    IO.puts "#{__MODULE__} initialized"

    {:ok, empty_histogram}
  end

  ### Client

  def view do
    IO.puts "EISA HOISA"
    GenServer.call(__MODULE__, :view)
  end

  def record(kanji_string) do
    GenServer.cast(__MODULE__, {:record, kanji_string})
  end

  ### Callbacks

  def handle_call(:view, _from, histogram) do
    {:reply, histogram, histogram}
  end

  def handle_cast({:record, ""}, histogram), do: {:noreply, histogram}
  def handle_cast({:record, kanji_string}, histogram) do
    updated_histogram = String.split(kanji_string, "")
                        |> Enum.reduce(histogram, fn kanji, current_histogram ->
                             Map.update(current_histogram, kanji, 1, &(&1 + 1))
                           end)

    IO.puts "Updated histogram"
    {:noreply, updated_histogram}
  end
end
