defmodule Fairbanks.ForecastControllerTest do
  use FairbanksWeb.ConnCase

  alias FairbanksWeb.Forecast
  @valid_attrs %{description: "some content", publication_date: "Thu, 15 Jun 2017 00:00:00 -0400", title: "Daily Forecast: June 15, 2017", uri: "http://www.fairbanksmuseum.org/eye-on-the-sky/2017-06-15", id: "7488a646-e31f-11e4-aace-600308960662"}
  @invalid_attrs %{}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, Routes.forecast_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen resource", %{conn: conn} do
    forecast = Repo.insert! %Forecast{}
    conn = get conn, Routes.forecast_path(conn, :show, forecast)
    assert json_response(conn, 200)["data"] == %{
      "id" => forecast.id,
      "title" => forecast.title,
      "uri" => forecast.uri,
      "publication_date" => forecast.publication_date,
      "description" => forecast.description,
      "detailed_summary" => forecast.detailed_summary,
      "extended_summary" => forecast.extended_summary,
      "recreational_summary" => forecast.recreational_summary,
      "soundcloud_id" => forecast.soundcloud_id }
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, Routes.forecast_path(conn, :show, Ecto.UUID.generate())
    end
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    conn = post conn, Routes.forecast_path(conn, :create), forecast: @valid_attrs
    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(Forecast, @valid_attrs)
  end

  test "custom date type can be cast, dumped, and loaded", %{conn: conn} do
    post conn, Routes.forecast_path(conn, :create), forecast: @valid_attrs
    forecast = Repo.get_by(Forecast, @valid_attrs)
    assert forecast.publication_date == ~D[2017-06-15]
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, Routes.forecast_path(conn, :create), forecast: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn} do
    forecast = Repo.insert! %Forecast{}
    conn = put conn, Routes.forecast_path(conn, :update, forecast), forecast: @valid_attrs
    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(Forecast, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    forecast = Repo.insert! %Forecast{}
    conn = put conn, Routes.forecast_path(conn, :update, forecast), forecast: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen resource", %{conn: conn} do
    forecast = Repo.insert! %Forecast{}
    conn = delete conn, Routes.forecast_path(conn, :delete, forecast)
    assert response(conn, 204)
    refute Repo.get(Forecast, forecast.id)
  end

  test "renders the forecast summary as an object when source is an array", %{conn: conn} do
    scraped_data = [%{content: "p1"}, %{content: "p2"}]
    forecast = Repo.insert! %Forecast{detailed_summary: Map.new([{Forecast.summary_key, scraped_data}])}
    conn = get conn, Routes.forecast_path(conn, :update, forecast), forecast: @valid_attrs
    summary = json_response(conn, 200)["data"]["detailed_summary"]
    assert is_map(summary)
    assert is_list(summary[Forecast.summary_key |> Atom.to_string])
  end

  test "renders today's forecast", %{conn: conn} do
    today = Fairbanks.Timestamp.today()
    Repo.insert! %Forecast{publication_date: today}
    conn = get conn, Routes.forecast_path(conn, :show, "today")
    data = json_response(conn, 200)["data"]
    assert data["publication_date"] == Date.to_iso8601(today)
  end

  test "renders an empty forecast when today's doesn't exist", %{conn: conn} do
    conn = get conn, Routes.forecast_path(conn, :show, "today")
    data = json_response(conn, 200)["data"]
    assert data["publication_date"] == nil
  end

end
