defmodule Fairbanks.ForecastControllerTest do
  use Fairbanks.ConnCase

  alias Fairbanks.Forecast
  @valid_attrs %{soundcloud_id: "some content", soundcloud_url: "some content", title: "some content", today_desc: "some content", tomorrow_desc: "some content", tomorrow_night_desc: "some content", tonight_desc: "some content", permalink: "some content", id: "7488a646-e31f-11e4-aace-600308960662"}
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
      "permalink" => forecast.permalink,
      "soundcloud_url" => forecast.soundcloud_url,
      "soundcloud_id" => forecast.soundcloud_id,
      "today_desc" => forecast.today_desc,
      "tonight_desc" => forecast.tonight_desc,
      "tomorrow_desc" => forecast.tomorrow_desc,
      "tomorrow_night_desc" => forecast.tomorrow_night_desc}
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
