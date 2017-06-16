defmodule Fairbanks.ForecastView do
  use Fairbanks.Web, :view

  def render("index.json", %{forecasts: forecasts}) do
    %{data: render_many(forecasts, Fairbanks.ForecastView, "forecast.json")}
  end

  def render("show.json", %{forecast: forecast}) do
    %{data: render_one(forecast, Fairbanks.ForecastView, "forecast.json")}
  end

  def render("forecast.json", %{forecast: forecast}) do
    %{id: forecast.id,
      title: forecast.title,
      uri: forecast.uri,
      description: forecast.description}
  end
end
