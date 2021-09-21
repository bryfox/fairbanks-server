defmodule Fairbanks.ForecastParser do
  @moduledoc """
  HTML parser for forecast content.
  Repsonsible for taking HTML (string) input and converting to a Forecast changeset.
  """
  require Logger
  alias FairbanksWeb.Forecast

  @doc """
  html_to_changeset
  """
  def html_to_changeset(html, %Forecast{} = forecast) do
    build_changeset({Floki.parse(html), forecast})
  end
  defp html_to_changeset(:ignore), do: :ignore
  defp html_to_changeset(:error), do: :error

  # Top-level comments produce a list html_tree, but we can operate on it the same
  @spec build_changeset(tuple | :error | :ignore) :: tuple | :error | :ignore
  defp build_changeset({dom, forecast}) when is_tuple(dom) or is_list(dom) do
    soundcloud = parse_soundcloud(Floki.find(dom, "#detailed .soundcloud"))
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
  def soundcloud_src_to_id(nil), do: nil

  defp parse_soundcloud(html_tree) when is_tuple(html_tree) or is_list(html_tree) do
    src = Floki.find(html_tree, ".soundcloud iframe")
          |> Floki.attribute("src")
          |> first_attr
    id = soundcloud_src_to_id(src)
    %{iframe_src: src, id: id}
  end

  defp first_attr([]), do: nil
  defp first_attr(attr_list) when is_list(attr_list), do: hd attr_list

  # Section: details, extended, or recreational
  def parse_section(html_tree) when is_tuple(html_tree) or is_list(html_tree) do
    forecast = html_tree |> Floki.find(".forecast")
    html = forecast |> Floki.raw_html
    summary = forecast
              |> Floki.find("h1, h2, h3, p")
              |> Enum.flat_map(&__MODULE__.parse_forecast_content/1)
    %{html: html, summary: summary}
  end

  @doc """
  Recursively parse HTML forecasts.
  The input is a tuple from a Floki parsing result: `{tagName, attrs, innerHtml}`.
  Attrs are ignored.
  """
  @spec parse_forecast_content(tuple) :: list
  # When innerHTML contains a single text node, extract the tag & content
  # Example: {"h2", [], ["Archived Detailed Forecast"]}
  def parse_forecast_content({tag, _, [content]} = html_tree) when is_binary(content) do
    Logger.debug("Simple string: " <> inspect(html_tree))
    [%{tag: tag, content: content}]
  end

  # When tag contains nothing, ignore
  # Example: ["br", [], []]
  def parse_forecast_content({tag, _, []}) do
    Logger.debug("Ignore empty " <> tag)
    []
  end

  # When innerHTML contains further HTML content (e.g., a <p> containing <br>s),
  # we parse each individually.
  # There's one level of redirection over the recursion to supply a parent tag, which fills in for tagless nodes.
  # In the following example, <p> content is separated by <br>s; we want to render two paragraphs
  # with the innerText split into two <p>s.
  # Example: {"p", [], ["Sunny", {"br", [], []}, "Winds today light"]}
  def parse_forecast_content({tag, _, content} = html_tree) when is_list(content) do
    Logger.debug("Nested content: " <> inspect(html_tree))
    Enum.flat_map(content, fn(x) -> parse_forecast_content_with_parent_tag(x, tag) end)
  end

  # parse_forecast_content_with_parent_tag takes care of parsing inner content, taking an additional
  # parent tag; see parse_forecast_content/1.
  @spec parse_forecast_content_with_parent_tag(tuple, String) :: list
  # The child (inner) content is itself a DOM node
  # Example content: {"br", [], []}
  defp parse_forecast_content_with_parent_tag({tag, _, _} = html_tree, _parent_tag) when is_binary(tag) do
    __MODULE__.parse_forecast_content(html_tree)
  end

  # The child (inner) content is a textNode
  # Example content: "Winds today light"
  defp parse_forecast_content_with_parent_tag(content, parent_tag) when is_binary(content) do
    __MODULE__.parse_forecast_content({parent_tag, [], [content]})
  end

end
