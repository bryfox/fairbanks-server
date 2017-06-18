defmodule Fairbanks.Importing.Coordinator do
  @moduledoc """
  This module is the initial entry point into data importing.
  It delegates tasks to the FeedBroker and other workers.
  """
  require Logger
  alias Fairbanks.Importing
  use GenServer

  @one_hour 1000 * 60 * 60
  # @update_interval @one_hour
  @update_interval 3000

  @doc """
  Start periodic update checks & downloads.
  This is the only public-facing interface;
  update behavior will be managed internally.
  """
  def start_link do
    GenServer.start_link(__MODULE__, name: __MODULE__)
  end

  ###########################
  # GenServer callbacks
  ###########################

  def init(state) do
    {:ok, feed_broker } = Importing.FeedBroker.start_link
    {:ok, details_broker } = Importing.DetailsBroker.start_link
    state = Keyword.put_new(state, :feed_broker, feed_broker)
    state = Keyword.put_new(state, :details_broker, details_broker)
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
    result = Importing.FeedBroker.import(state[:feed_broker])
    Logger.info("FeedBroker result: " <> inspect(result))
    result = Importing.DetailsBroker.import(state[:details_broker])
    Logger.info("DetailsBroker result: " <> inspect(result))

    # result = fetch_rss() && fetch_details()
    schedule_update_check()
    {:noreply, state}
  end

  ###########################
  # Helpers
  ###########################

  # Responsible for (continually) scheduling a new update check
  # See handle_info(:update_check)
  defp schedule_update_check, do: Process.send_after(self(), :update_check, @update_interval)

end
