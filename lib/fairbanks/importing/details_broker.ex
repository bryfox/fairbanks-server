defmodule Fairbanks.Importing.DetailsBroker do
  require Logger
  use GenServer
  alias Fairbanks.Forecast

  @doc """
  Once started, will await an :import call
  """
  def start_link do
    GenServer.start_link(__MODULE__, name: __MODULE__)
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

  def init(state) do
    {:ok, state}
  end

  def handle_call({:import}, from, state) do
    {:reply, import_details(), state}
  end

  def terminate(reason, state) do
  end

  ###########################
  # Update pipeline
  ###########################

  @doc """
  Download and persist details from the forecast's URI.
  
  Returns a state:
    :ok - forecast details were updated in DB
    :ignore - no updates were needed, so the update was skipped
    :error - update was attempted, but failed. If forecast.needs_details? is still true,
        then this update may be retried later.
  """
  @spec import_details() :: :ok | :ignore | :error
  defp import_details do
    updatable_forecast()
    |> download()
    |> parse()
    |> build_changeset()
    |> update_db()
  end

  # Returns the latest forecast, if it needs details populated, or :ignore
  defp updatable_forecast do
    forecast = Forecast.latest()
    if Forecast.needs_details?(forecast), do: forecast, else: :ignore
  end

  @spec download(String) :: { atom, any }
  defp download(%Forecast{uri: url} = forecast) when is_binary(url) do
    Logger.info("DetailsBroker downloading " <> url)
    # TODO: Could specify retry with :ignore when status code deems appropriate
    case HTTPoison.get(url) do
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
  defp download(:ignore), do: :ignore

  # Handle download response
  @spec parse({:ok , String} | :ignore | :error) :: tuple | list | :ignore | :error
  defp parse({:ok, html, forecast}), do: { Floki.parse(html), forecast }
  defp parse(:ignore), do: :ignore
  defp parse(:error), do: :error

  # Top-level comments produce a list html_tree, but we can operate on it the same
  @spec build_changeset(tuple | :error | :ignore) :: tuple | :error | :ignore
  defp build_changeset({dom, forecast}) when is_tuple(dom) or is_list(dom) do
    soundcloud = parse_soundcloud(Floki.find(dom, ".soundcloud"))
    detailed = parse_section(Floki.find(dom, "#detailed"))
    extended = parse_section(Floki.find(dom, "#extended"))
    recreational = parse_section(Floki.find(dom, "#recreational"))

    Logger.debug("Scrape results:")
    Logger.debug(inspect(soundcloud))
    Logger.debug(inspect(detailed))
    Logger.debug(inspect(extended))
    Logger.debug(inspect(recreational))

    # TODO: may want to update details_processed separately for best effort...
    # if our scraping fails, we shouldn't keep trying.
    key = Forecast.summary_key
    params = %{ details_processed: true,
                soundcloud_id: soundcloud.id,
                detailed_summary: Map.new([{key, detailed.summary}]),
                extended_summary: Map.new([{key, extended.summary}]),
                recreational_summary: Map.new([{key, recreational.summary}])}
    Forecast.changeset(forecast, params)
  end
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

  ###########################
  # Helpers
  ###########################

  # "https://w.soundcloud.com/player/?visual=false&url=https%3A%2F%2Fapi.soundcloud.com%2Ftracks%2F328230856&show_artwork=false&maxwidth=400px&maxheight=166px&show_comments=false&color=F7941E"
  # -> "328230856"
  # Public for unit testing
  def soundcloud_src_to_id(src) when is_binary(src) do
    Regex.named_captures(~r/&url=(?<soundcloud_url>[^&]+)/, src)
    |> Map.fetch!("soundcloud_url")
    |> URI.decode
    |> String.split("/")
    |> List.last
  end

  defp parse_soundcloud(html_tree) when is_tuple(html_tree) or is_list(html_tree) do
    src = Floki.find(html_tree, ".soundcloud iframe")
          |> Floki.attribute("src")
          |> hd
    id = soundcloud_src_to_id(src)
    %{iframe_src: src, id: id}
  end

  # Section: details, extended, or recreational
  defp parse_section(html_tree) when is_tuple(html_tree) or is_list(html_tree) do
    forecast = html_tree |> Floki.find(".forecast")
    html = forecast |> Floki.raw_html
    summary = forecast |>Floki.find("h1, h2, h3, p") |> Enum.map(fn(tup) -> %{tag: elem(tup, 0), content: hd elem(tup, 2)} end)
    %{html: html, summary: summary}
  end

end
