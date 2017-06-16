defmodule Fairbanks.ForecastTest do
  use Fairbanks.ModelCase

  alias Fairbanks.Forecast

  @valid_attrs %{soundcloud_id: "some content", soundcloud_url: "some content", title: "some content", today_desc: "some content", tomorrow_desc: "some content", tomorrow_night_desc: "some content", tonight_desc: "some content", permalink: "some content", id: "7488a646-e31f-11e4-aace-600308960662"}
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
