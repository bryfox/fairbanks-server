defmodule Fairbanks.Importing.FeedBroker do
  require Logger
  alias Fairbanks.Forecast

  # TODO: move to env config
  @feed_url "http://localhost:8000/rss.xml"

  @doc """
  Download the RSS feed from the remote URL
  """
  @spec import() :: {:ok, integer} | {:error, String}
  def import do
    case fetch_rss?() do
      false -> :ignore
      true -> @feed_url
              |> download()
              |> parse()
              |> parse_entries()
              |> report_status()
    end
  end

  ###########################
  # Update pipeline
  ###########################

  @spec download(String) :: { atom, any }
  defp download(url) do
    Logger.info("FeedBroker downloading " <> url)
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        { :ok, body }
      {:ok, %HTTPoison.Response{status_code: code, body: _}} ->
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
