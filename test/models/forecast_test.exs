defmodule Fairbanks.ForecastTest do
  use Fairbanks.ModelCase

  alias FairbanksWeb.Forecast

  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Forecast.changeset(%Forecast{}, valid_attrs())
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Forecast.changeset(%Forecast{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "changeset persists all model attributes" do
    changeset = Forecast.changeset(%Forecast{}, valid_attrs())
    forecast = Repo.insert! changeset
    refute forecast.details_processed
    changeset = Forecast.changeset(forecast, %{details_processed: true})
    forecast = Repo.update! changeset
    assert forecast.details_processed
  end

  describe "latest" do
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

    test "latest returns most recent" do
      Repo.insert! %Forecast{publication_date: ~D[2017-01-01]}
      forecast = Repo.insert! %Forecast{publication_date: ~D[2017-01-02]}
      assert Forecast.latest().id == forecast.id
    end
  end

  describe "needed" do
    test "an existing forecast is not needed" do
      Repo.insert! %Forecast{publication_date: ~D[2017-01-01]}
      refute Forecast.needed_for_date?(~D[2017-01-01])
    end

    test "a missing forecast is needed" do
      Repo.insert! %Forecast{publication_date: ~D[2017-01-01]}
      assert Forecast.needed_for_date?(~D[2017-01-02])
    end

    test "A forecast doesn't need details if it's marked as processed" do
      forecast = Repo.insert! %Forecast{details_processed: true, soundcloud_id: "123"}
      refute Forecast.needs_details?(forecast)
    end

    test "A forecast does need details if it lacks soundcloud_id" do
      forecast = Repo.insert! %Forecast{details_processed: true}
      assert Forecast.needs_details?(forecast)
    end
  end

  describe "today's forecast" do
    test "is queryable" do
      forecast = Repo.insert! %Forecast{publication_date: Fairbanks.Timestamp.today()}
      assert Forecast.for_today().publication_date == forecast.publication_date
    end

    test "returns nil when there is none" do
      forecast = Repo.insert! %Forecast{publication_date: Date.from_iso8601!("2015-01-01")}
      assert forecast.id == Forecast.latest().id
      assert nil == Forecast.for_today()
    end
  end

  defp valid_attrs do
    Fairbanks.ModelCase.valid_forecast_attrs()
  end
end
