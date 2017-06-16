defmodule Fairbanks.ForecastControllerTest do
  use Fairbanks.ConnCase

  alias Fairbanks.Forecast
  @valid_attrs %{description: "some content", publication_date: "Thu, 15 Jun 2017 00:00:00 -0400", title: "Daily Forecast: June 15, 2017", uri: "http://www.fairbanksmuseum.org/eye-on-the-sky/2017-06-15", id: "7488a646-e31f-11e4-aace-600308960662"}
  @invalid_attrs %{}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, forecast_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen resource", %{conn: conn} do
    forecast = Repo.insert! %Forecast{}
    conn = get conn, forecast_path(conn, :show, forecast)
    assert json_response(conn, 200)["data"] == %{
      "id" => forecast.id,
      "title" => forecast.title,
      "uri" => forecast.uri,
      "publication_date" => forecast.publication_date,
      "description" => forecast.description}
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, forecast_path(conn, :show, Ecto.UUID.generate())
    end
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    conn = post conn, forecast_path(conn, :create), forecast: @valid_attrs
    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(Forecast, @valid_attrs)
  end

  test "custom date type can be cast, dumped, and loaded", %{conn: conn} do
    post conn, forecast_path(conn, :create), forecast: @valid_attrs
    forecast = Repo.get_by(Forecast, @valid_attrs)
    assert forecast.publication_date == ~D[2017-06-15]
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, forecast_path(conn, :create), forecast: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn} do
    forecast = Repo.insert! %Forecast{}
    conn = put conn, forecast_path(conn, :update, forecast), forecast: @valid_attrs
    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(Forecast, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    forecast = Repo.insert! %Forecast{}
    conn = put conn, forecast_path(conn, :update, forecast), forecast: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen resource", %{conn: conn} do
    forecast = Repo.insert! %Forecast{}
    conn = delete conn, forecast_path(conn, :delete, forecast)
    assert response(conn, 204)
    refute Repo.get(Forecast, forecast.id)
  end
end
