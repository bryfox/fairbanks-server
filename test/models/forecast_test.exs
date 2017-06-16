defmodule Fairbanks.ForecastTest do
  use Fairbanks.ModelCase

  alias Fairbanks.Forecast

  @valid_attrs %{description: "some content", publication_date: ~D[2017-06-15], title: "Daily Forecast: June 15, 2017", uri: "http://www.fairbanksmuseum.org/eye-on-the-sky/2017-06-15", id: "7488a646-e31f-11e4-aace-600308960662"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Forecast.changeset(%Forecast{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Forecast.changeset(%Forecast{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "today's model is latest" do
    forecast = Repo.insert! %Forecast{}
    assert Forecast.latest == forecast
  end

  test "that we have the latest" do
    Repo.insert! %Forecast{publication_date: Date.utc_today()}
    assert Forecast.have_latest?
  end

  test "that we don't have the latest when publication date is missing" do
    Repo.insert! %Forecast{}
    assert false == Forecast.have_latest?
  end

  test "that we don't have the latest when publication date is old" do
    Repo.insert! %Forecast{publication_date: ~D[2017-01-01]}
    assert false == Forecast.have_latest?
  end

  test "that an existing forecast is not needed" do
    Repo.insert! %Forecast{publication_date: ~D[2017-01-01]}
    assert false == Forecast.needed_for_date?(~D[2017-01-01])
  end

  test "that a missing forecast is needed" do
    Repo.insert! %Forecast{publication_date: ~D[2017-01-01]}
    assert Forecast.needed_for_date?(~D[2017-01-02])
  end

end
