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
      permalink: forecast.permalink,
      soundcloud_url: forecast.soundcloud_url,
      soundcloud_id: forecast.soundcloud_id,
      today_desc: forecast.today_desc,
      tonight_desc: forecast.tonight_desc,
      tomorrow_desc: forecast.tomorrow_desc,
      tomorrow_night_desc: forecast.tomorrow_night_desc}
  end
end
