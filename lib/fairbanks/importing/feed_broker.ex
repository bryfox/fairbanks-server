defmodule Fairbanks.Importing.FeedBroker do
  require Logger
  use GenServer
  alias Fairbanks.Forecast

  @doc """
  Once started, will await an :import call
  """
  def start_link(user_agent) do
    GenServer.start_link(__MODULE__, user_agent, name: __MODULE__)
  end

  def import(broker, url) do
    GenServer.call(broker, {:import, url})
  end

  def stop(broker, reason \\ :normal, timeout \\ :infinity) do
    GenServer.stop(broker, reason, timeout)
  end

  ###########################
  # GenServer callbacks
  ###########################

  def init(user_agent) do
    Logger.info("FeedBroker initialized with UA " <> inspect(user_agent))
    state = [user_agent: user_agent]
    {:ok, state}
  end

  @doc """
  Download the RSS feed from the remote URL, if needed.
  If we already have the forecast for today, the download is skipped.

  The reply is an atom representing a result:
    :ok - forecast details were updated in DB
    :ignore - no updates were needed, so the update was skipped
    :error - update was attempted, but failed. If forecast.needs_details? is still true,
        then this update may be retried later.
  """
  def handle_call({:import, url}, _from, state) do
    {:reply, import_if_needed(url, state[:user_agent]), state}
  end

  # def terminate(_reason, _state) do
  # end

  ###########################
  # Update pipeline
  ###########################

  defp import_if_needed(url, ua) when is_binary(url) do
    case fetch_rss?() do
      true -> fetch_rss(url, ua)
      false -> :ignore
    end
  end

  @spec fetch_rss(String, String) :: {:ok, integer} | {:error, String}
  defp fetch_rss(url, ua) when is_binary(url) do
    url
    |> download(ua)
    |> parse()
    |> parse_entries()
    |> report_status()
  end
  defp fetch_rss(nil, _), do: Logger.warn("Ignoring request for nil feed URL") && :ignore

  @spec download(String, String) :: { atom, any }
  defp download(url, user_agent) do
    Logger.info("FeedBroker downloading " <> url)
    case HTTPoison.get(url, [{"User-Agent", user_agent}]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        { :ok, body }
      {:ok, %HTTPoison.Response{status_code: code}} ->
        {:error, "Unexpected HTTP status: " <> inspect(code)}
      {:ok, other} ->
        { :error, "Unexpected response: " <> inspect(other)}
      {:error, err} ->
        { :error, "Download error: " <> inspect(err)}
    end
  end

  # Handle download response
  @spec parse({:ok | :error, String}) :: tuple | :error
  defp parse({:ok, xml}), do: FeederEx.parse(xml)
  defp parse({:error, msg}), do: Logger.error(msg) && :error

  # Handle entries from FeederEx.parse(xml)
  # If successful, returns the count of entries created.
  @spec parse({atom, String} | :error) :: integer | :error
  defp parse_entries({:ok, feed, _}), do: feed.entries |> Enum.reverse |> Enum.reduce(0, &create_forecast/2)
  defp parse_entries({:error, err}), do: Logger.error(inspect(err)) && :error
  # Passthrough error, not from FeederEx:
  defp parse_entries(:error), do: :error
  # Parsing errors from Feeder:
  defp parse_entries(_), do: :error

  # Provides return value to public API
  @spec report_status(integer | :error) :: :ignore | :ok | :error
  defp report_status(0), do: Logger.info("Nothing to import") && :ignore
  defp report_status(count) when is_integer(count), do: Logger.info(inspect(count) <> " new forecast(s) created.") && :ok
  defp report_status(:error), do: :error

  ###########################
  # Helpers
  ###########################

  # check for remote updates if we don't have latest already,
  # and if it's reasonably late in the day (Fairbanks Museum time)
  defp fetch_rss?(after_utc_hour) when is_integer(after_utc_hour) do
    late_enough = DateTime.utc_now().hour >= after_utc_hour
    unless late_enough, do: Logger.info("Scraping disabled (time of day)")
    late_enough && not(Forecast.have_latest?)
  end
  defp fetch_rss?, do: fetch_rss?(5)

  # Insert into DB if needed. Return an accumulator to be used by parse_entries/1.
  defp create_forecast(%FeederEx.Entry{} = entry, acc) do
    params = %{title: entry.title, uri: entry.link, description: entry.summary, publication_date: entry.updated}
    changeset = Forecast.changeset(%Forecast{}, params)
    if Forecast.needed_for_date?(changeset) && insert_changeset(changeset) do
      acc + 1
    else
      acc
    end
  end
  defp create_forecast(_, _), do: :error

  # Insert record into DB and return true if successful (else false)
  @spec insert_changeset(%Ecto.Changeset{}) :: boolean
  defp insert_changeset(%Ecto.Changeset{} = changeset) do
    case Fairbanks.Repo.insert(changeset) do
        {:ok, _} -> true
        {:error, changeset} -> Logger.error(inspect(changeset)) && false
    end
  end
end
