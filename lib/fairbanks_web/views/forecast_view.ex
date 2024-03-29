defmodule FairbanksWeb.ForecastView do
  use Fairbanks.Web, :view

  def render("index.json", %{forecasts: forecasts}) do
    %{data: render_many(forecasts, FairbanksWeb.ForecastView, "forecast.json")}
  end

  def render("show.json", %{forecast: forecast}) do
    %{data: render_one(forecast, FairbanksWeb.ForecastView, "forecast.json")}
  end

  def render("forecast.json", %{forecast: forecast}) do
    %{id: forecast.id,
      title: forecast.title,
      uri: forecast.uri,
      publication_date: forecast.publication_date,
      description: forecast.description,
      soundcloud_id: forecast.soundcloud_id,
      detailed_summary: forecast.detailed_summary,
      extended_summary: forecast.extended_summary,
      recreational_summary: forecast.recreational_summary}
  end
end
