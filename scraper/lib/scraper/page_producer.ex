defmodule PageProducer do
  use GenStage
  require Logger

  def scrape_pages(pages) when is_list(pages) do
    GenStage.cast(__MODULE__, {:pages, pages})
  end

  def start_link(_args) do
    initial_state = []
    GenStage.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  def init(initial_state) do
    Logger.info("Page producer init")
    {:producer, initial_state, buffer_size: 1}
  end

  def handle_cast({:pages, pages}, state) do
    {:noreply, pages, state}
  end

  def handle_demand(demand, state) do
    Logger.info("PageProducer received demand for #{demand} pages")
    events = []
    {:noreply, events, state}
  end
end
