defmodule Fairbanks.Importing.Coordinator do
  @moduledoc """
  This module is the initial entry point into data importing.
  It delegates tasks to the FeedBroker and other workers.
  """
  require Logger
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

  @doc """
  Note: Feed & detail updating are not pipelined;
  the feed update may :ignore, but DetailsBroker
  should still update if needed (e.g., in case of
  an earlier temporary failure.)
  """
  def handle_info(:update_check, state) do
    result = fetch_rss() && fetch_details()
    Logger.info(":update_check completed, " <> inspect(result))
    schedule_update_check()
    {:noreply, state}
  end

  ###########################
  # Helpers
  ###########################

  # See handle_info(:update_check)
  defp schedule_update_check, do: Process.send_after(self(), :update_check, @update_interval)

  defp fetch_rss(), do: Fairbanks.Importing.FeedBroker.import
  defp fetch_details(), do: Fairbanks.Importing.DetailsBroker.import

end
