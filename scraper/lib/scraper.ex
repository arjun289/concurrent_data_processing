defmodule Scraper do
  @moduledoc """
  Documentation for Scraper.
  """

  def online?(_url) do
    # Pretend to check if the service is online or not
    work()

    Enum.random([false, true, true])
  end

  def work() do
    1..5
    |> Enum.random()
    |> :timer.seconds()
    |> Process.sleep()
  end
end
