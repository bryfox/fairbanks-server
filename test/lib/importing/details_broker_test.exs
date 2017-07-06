defmodule Fairbanks.Importing.DetailsBrokerTest do
  use Fairbanks.ModelCase

  alias Fairbanks.Importing.DetailsBroker
  alias Fairbanks.Forecast
  import Mock

  @test_user_agent "test_user_agent"

  setup do
    {:ok, broker} = DetailsBroker.start_link(@test_user_agent)
    {:ok, broker: broker}
  end

  test "succeeds when details needed", %{broker: broker} do
    changeset = Forecast.changeset(%Forecast{}, Fairbanks.ModelCase.valid_forecast_attrs())
    Fairbanks.Repo.insert!(changeset)
    resp = {:ok, %HTTPoison.Response{status_code: 200, body: ""}}
    with_mock HTTPoison, [get: fn(_url, _) -> resp end] do
      assert :ok = DetailsBroker.import(broker)
    end
  end

  test "ignores when there are no forecasts", %{broker: broker} do
    resp = {:ok, %HTTPoison.Response{status_code: 200, body: ""}}
    with_mock HTTPoison, [get: fn(_url, _) -> resp end] do
      assert :ignore = DetailsBroker.import(broker)
    end
  end

  @tag capture_log: true
  test "indicates error if server is down", %{broker: broker} do
    attrs = Fairbanks.ModelCase.valid_forecast_attrs()
    attrs = Map.put(attrs, :uri, "http://localhost:9001")
    changeset = Forecast.changeset(%Forecast{}, attrs)
    Fairbanks.Repo.insert!(changeset)
    assert :error = DetailsBroker.import(broker)
  end

end
