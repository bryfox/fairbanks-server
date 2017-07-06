defmodule Fairbanks.Importing.DetailsBroker do
  require Logger
  use GenServer
  alias Fairbanks.Forecast
  alias Fairbanks.ForecastParser

  @doc """
  Once started, will await an :import call
  """
  def start_link(user_agent) do
    GenServer.start_link(__MODULE__, user_agent, name: __MODULE__)
  end

  @doc """
  Download and persist details from the forecast's URI.
  
  Returns a state:
    :ok - forecast details were updated in DB
    :ignore - no updates were needed, so the update was skipped
    :error - update was attempted, but failed. If forecast.needs_details? is still true,
        then this update may be retried later.
  """
  def import(broker) do
    GenServer.call(broker, {:import})
  end

  def stop(broker, reason \\ :normal, timeout \\ :infinity) do
    GenServer.stop(broker, reason, timeout)
  end

  ###########################
  # GenServer callbacks
  ###########################

  def init(user_agent) do
    Logger.info("DetailsBroker initialized with UA " <> inspect(user_agent))
    state = [user_agent: user_agent]
    {:ok, state}
  end

  @doc """
  Download and persist details from the forecast's URI.
  
  The reply is an atom representing a result:
    :ok - forecast details were updated in DB
    :ignore - no updates were needed, so the update was skipped
    :error - update was attempted, but failed. If forecast.needs_details? is still true,
        then this update may be retried later.
  """
  def handle_call({:import}, _from, state) do
    {:reply, import_details(state[:user_agent]), state}
  end

  # def terminate(_reason, _state) do
  # end

  ###########################
  # Update pipeline
  ###########################

  # see handle_call
  @spec import_details(String) :: :ok | :ignore | :error
  defp import_details(ua) do
    updatable_forecast()
    |> download(ua)
    |> build_changeset()
    |> update_db()
  end

  # Returns the latest forecast, if it needs details populated, or :ignore
  @spec updatable_forecast() :: %Forecast{} | :ignore
  defp updatable_forecast do
    forecast = Forecast.latest()
    if forecast != nil and Forecast.needs_details?(forecast), do: forecast, else: :ignore
  end

  @spec download(String, String) :: { atom, any }
  defp download(%Forecast{uri: url} = forecast, user_agent) when is_binary(url) do
    Logger.info("DetailsBroker downloading " <> url)
    # TODO: Could specify retry with :ignore when status code deems appropriate
    case HTTPoison.get(url, [{"User-Agent", user_agent}]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        { :ok, body, forecast }
      {:ok, %HTTPoison.Response{status_code: code, body: _}} ->
        Logger.error("[Details] Unexpected HTTP status: " <> inspect(code)) && :error
      {:ok, other} ->
        Logger.error("[Details] Unexpected response: " <> inspect(other)) && :error
      {:error, err} ->
        Logger.error("[Details] Download error: " <> inspect(err)) && :error
    end
  end
  defp download(:ignore, _), do: :ignore

  # Handle download response
  @spec build_changeset({:ok , String} | :ignore | :error) :: tuple | list | :ignore | :error
  defp build_changeset({:ok, html, forecast}), do: ForecastParser.html_to_changeset(html, forecast)
  defp build_changeset(:ignore), do: :ignore
  defp build_changeset(:error), do: :error

  # Primary key (id) must be part of changeset's original date for an update
  defp update_db(%Ecto.Changeset{data: %{ id: _ }} = changeset) do
    Logger.info("UPDATING " <> inspect(changeset))
    case Fairbanks.Repo.update(changeset) do
        {:ok, _} -> :ok
        {:error, changeset} -> Logger.error(inspect(changeset)) && :error
    end
  end
  defp update_db(:ignore), do: :ignore
  defp update_db(:error), do: :error

end
