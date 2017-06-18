defmodule Fairbanks.Importing.DetailsBroker do
  require Logger
  alias Fairbanks.Forecast

  def import do
    forecast_url()
    |> download()
    |> parse()
    |> build_changeset()
    |> update_db()
  end

  ###########################
  # Helpers
  ###########################

  # For local dev only
  defp forecast_url, do: "http://localhost:8000/2017-06-15.html"

  @spec download(String) :: { atom, any }
  defp download(url) do
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        { :ok, body }
      {:ok, %HTTPoison.Response{status_code: code, body: _}} ->
        {:error, "[Details] Unexpected HTTP status: " <> inspect(code)}
      {:ok, other} ->
        { :error, "[Details] Unexpected response: " <> inspect(other)}
      {:error, err} ->
        { :error, "[Details] Download error: " <> inspect(err)}
    end
  end

  # Handle download response
  @spec parse({:ok | :error, String}) :: tuple | :error
  defp parse({:ok, html}), do: Floki.parse(html)
  defp parse({:error, msg}), do: Logger.error(msg) && :error

  defp build_changeset(dom) when is_tuple(dom) or is_list(dom) do
    detailed = process_tab(Floki.find(dom, "#detailed"))
    extended = process_tab(Floki.find(dom, "#extended"))
    recreational = process_tab(Floki.find(dom, "#recreational"))
    Logger.info("Scrape results: " <> inspect({detailed, extended, recreational}))

    #changeset

    :ok
  end
  # Top-level comments produce a list html_tree, but we can operate on it the same
  # defp build_changeset(dom) when is_list(dom), do: build_changeset(dom)
  defp build_changeset(:error), do: :error

  # either #details or #extended
  defp process_tab(html_tree) when is_tuple(html_tree) or is_list(html_tree) do
    src = Floki.find(html_tree, ".soundcloud iframe")
          |> Floki.attribute("src")
          |> hd
    id = soundcloud_src_to_id(src)
    
    forecast = html_tree |> Floki.find(".forecast")
    html = forecast |> Floki.raw_html
    summary = forecast |>Floki.find("h1, h2, h3, p") |> Enum.map(fn(tup) -> %{tag: elem(tup, 0), content: hd elem(tup, 2)} end)

    %{soundcloud_iframe: src, soundcloud_id: id, html: html, summary: summary}
  end

  # "https://w.soundcloud.com/player/?visual=false&url=https%3A%2F%2Fapi.soundcloud.com%2Ftracks%2F328230856&show_artwork=false&maxwidth=400px&maxheight=166px&show_comments=false&color=F7941E"
  # -> "328230856"
  defp soundcloud_src_to_id(src) do
    Regex.named_captures(~r/&url=(?<soundcloud_url>[^&]+)/, src)
    |> Map.fetch!("soundcloud_url")
    |> URI.decode
    |> String.split("/")
    |> List.last
  end

  defp update_db(:ok), do: :ok
  defp update_db(:error), do: :error
end
