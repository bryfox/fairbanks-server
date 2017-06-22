defmodule Fairbanks.Importing.Coordinator do
  @moduledoc """
  This module is the initial entry point into data importing.
  It delegates tasks to the FeedBroker and other workers.
  """
  require Logger
  alias Fairbanks.Importing
  use GenServer

  @one_hour 1000 * 60 * 60
  @default_update_interval @one_hour
  @default_ua "hackney/weatherclient"
  @default_feed_url "http://localhost:8000/rss.xml"

  @doc """
  Start periodic update checks & downloads.
  This is the primary public-facing interface;
  update behavior will be managed internally.
  """
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def import_once do
    {:ok, feed_broker } = Importing.FeedBroker.start_link(configured_user_agent())
    {:ok, details_broker } = Importing.DetailsBroker.start_link(configured_user_agent())
    Logger.info Importing.FeedBroker.import(feed_broker, configured_feed_url())
    Logger.info Importing.DetailsBroker.import(details_broker)
    Importing.FeedBroker.stop(feed_broker, :normal)
    Importing.DetailsBroker.stop(details_broker, :normal)
  end

  ###########################
  # GenServer callbacks
  ###########################

  @doc """
  Starts brokers for feed & detail importing, and periodically checks for updates.

  An :update_interval can be specified in the initial state, or will default to one hour.
  Regardless, data brokers may skip update checks when deemed appropriate.

  Begins updates after the next update interval.

  User agent and data feed URL can (and should) be configured through the environment variables
  FAIRBANKS_USER_AGENT and FAIRBANKS_FEED_URL, respectively.
  """
  def init(state) do
    {:ok, feed_broker } = Importing.FeedBroker.start_link(configured_user_agent())
    {:ok, details_broker } = Importing.DetailsBroker.start_link(configured_user_agent())
    state = Keyword.put_new(state, :update_interval, @default_update_interval)
    state = Keyword.put_new(state, :feed_broker, feed_broker)
    state = Keyword.put_new(state, :details_broker, details_broker)

    schedule_update_check(state[:update_interval])
    {:ok, state}
  end

  @doc """
  Periodically check for feed & detailed forecast updates.

  Each update should be needed only once per day.

  Note: Feed & detail updating are not pipelined; the feed update may :ignore,
  but DetailsBroker should still update if needed (e.g., in case of an earlier temporary failure.)
  """
  def handle_info(:update_check, state) do
    Logger.info("Coordinator starting update_check. " <> configured_feed_url())
    result = Importing.FeedBroker.import(state[:feed_broker], configured_feed_url())
    Logger.info("FeedBroker result: " <> inspect(result))
    result = Importing.DetailsBroker.import(state[:details_broker])
    Logger.info("DetailsBroker result: " <> inspect(result))

    schedule_update_check(state[:update_interval])
    {:noreply, state}
  end

  ###########################
  # Helpers
  ###########################

  defp configured_feed_url do
    configured_string(Application.get_env(:fairbanks, :data_feed_url), @default_feed_url)
  end

  defp configured_user_agent do
    configured_string(Application.get_env(:fairbanks, :user_agent), @default_ua)
  end

  # Responsible for (continually) scheduling a new update check
  # See handle_info(:update_check)
  defp schedule_update_check(update_interval), do: Process.send_after(self(), :update_check, update_interval)

  defp configured_string({:system, env_var}, default) when is_binary(default), do: configured_string(System.get_env(env_var), default)
  defp configured_string(value, _default) when is_binary(value), do: value
  defp configured_string(_, default) when is_binary(default), do: default

end
