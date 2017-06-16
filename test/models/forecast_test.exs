defmodule Fairbanks.ForecastTest do
  use Fairbanks.ModelCase

  alias Fairbanks.Forecast

  @valid_attrs %{description: "some content", rss_timestamp: "Thu, 15 Jun 2017 00:00:00 -0400", title: "Daily Forecast: June 15, 2017", uri: "http://www.fairbanksmuseum.org/eye-on-the-sky/2017-06-15", id: "7488a646-e31f-11e4-aace-600308960662"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Forecast.changeset(%Forecast{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Forecast.changeset(%Forecast{}, @invalid_attrs)
    refute changeset.valid?
  end
end
