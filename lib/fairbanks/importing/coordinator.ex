defmodule Fairbanks.Importing.Coordinator do
  @moduledoc """
  This module is the initial entry point into data importing.
  It delegates tasks to the FeedBroker and other workers.
  """
  require Logger
  alias Fairbanks.Forecast
  use GenServer

  @one_hour 1000 * 60 * 60
  # @update_interval @one_hour
  @update_interval 3000

  @doc """
  Start periodic update checks & downloads.
  """
  def start_link do
    GenServer.start_link(__MODULE__, name: __MODULE__)
  end

  ###########################
  # GenServer callbacks
  ###########################

  def init(state) do
    schedule_update_check()
    {:ok, state}
  end

  def handle_info(:update_check, state) do
    result = update_check()
              |> fetch_rss
              |> fetch_details

    Logger.info(":update_check completed, " <> inspect(result))
    schedule_update_check()
    {:noreply, state}
  end

  ###########################
  # Helpers
  ###########################

  # TODO: abstract the GenServer/worker pattern to give us the :ignore/:ok/:error pattern

  defp update_check do
    if fetch_rss?(), do: :ok, else: :ignore
  end

  # check for remote updates if we don't have latest already,
  # and if it's reasonably late in the day (Fairbanks Museum time)
  defp fetch_rss? do
    DateTime.utc_now().hour >= 5 && not(Forecast.have_latest?)
  end

  defp fetch_rss(:ok), do:
    Fairbanks.Importing.FeedBroker.import
  defp fetch_rss(:ignore), do: :ignore

  defp fetch_details(:ok) do
    Logger.debug("TODO: fetch details")
  end
  defp fetch_details(:ignore), do: :ignore

  # See handle_info(:update_check)
  defp schedule_update_check  do
    Process.send_after(self(), :update_check, @update_interval)
  end

end
