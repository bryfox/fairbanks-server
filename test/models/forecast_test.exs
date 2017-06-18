defmodule Fairbanks.ForecastTest do
  use Fairbanks.ModelCase

  alias Fairbanks.Forecast

  @valid_attrs %{description: "some content", publication_date: ~D[2017-06-15], title: "Daily Forecast: June 15, 2017", uri: "http://www.fairbanksmuseum.org/eye-on-the-sky/2017-06-15", id: "7488a646-e31f-11e4-aace-600308960662", }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Forecast.changeset(%Forecast{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Forecast.changeset(%Forecast{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "changeset persists all model attributes" do
    changeset = Forecast.changeset(%Forecast{}, @valid_attrs)
    forecast = Repo.insert! changeset
    refute forecast.details_processed
    changeset = Forecast.changeset(forecast, %{details_processed: true})
    forecast = Repo.update! changeset
    assert forecast.details_processed
  end

  test "today's model is latest" do
    forecast = Repo.insert! %Forecast{}
    assert Forecast.latest.id == forecast.id
  end

  test "we have the latest" do
    Repo.insert! %Forecast{publication_date: Date.utc_today()}
    assert Forecast.have_latest?
  end

  test "we don't have the latest when publication date is missing" do
    Repo.insert! %Forecast{}
    refute Forecast.have_latest?
  end

  test "we don't have the latest when publication date is old" do
    Repo.insert! %Forecast{publication_date: ~D[2017-01-01]}
    refute Forecast.have_latest?
  end

  test "an existing forecast is not needed" do
    Repo.insert! %Forecast{publication_date: ~D[2017-01-01]}
    refute Forecast.needed_for_date?(~D[2017-01-01])
  end

  test "a missing forecast is needed" do
    Repo.insert! %Forecast{publication_date: ~D[2017-01-01]}
    assert Forecast.needed_for_date?(~D[2017-01-02])
  end

  test "latest returns most recent" do
    Repo.insert! %Forecast{publication_date: ~D[2017-01-01]}
    forecast = Repo.insert! %Forecast{publication_date: ~D[2017-01-02]}
    assert Forecast.latest().id == forecast.id
  end

  test "A forecast doesn't need details if it's marked as processed" do
    forecast = Repo.insert! %Forecast{details_processed: true}
    refute Forecast.needs_details?(forecast)
  end

end
