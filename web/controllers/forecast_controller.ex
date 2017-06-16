defmodule Fairbanks.ForecastController do
  use Fairbanks.Web, :controller

  alias Fairbanks.Forecast

  def index(conn, _params) do
    forecasts = Repo.all(Forecast)
    render(conn, "index.json", forecasts: forecasts)
  end

  def create(conn, %{"forecast" => forecast_params}) do
    changeset = Forecast.changeset(%Forecast{}, forecast_params)

    case Repo.insert(changeset) do
      {:ok, forecast} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", forecast_path(conn, :show, forecast))
        |> render("show.json", forecast: forecast)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Fairbanks.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    forecast = Repo.get!(Forecast, id)
    render(conn, "show.json", forecast: forecast)
  end

  def update(conn, %{"id" => id, "forecast" => forecast_params}) do
    forecast = Repo.get!(Forecast, id)
    changeset = Forecast.changeset(forecast, forecast_params)

    case Repo.update(changeset) do
      {:ok, forecast} ->
        render(conn, "show.json", forecast: forecast)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Fairbanks.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    forecast = Repo.get!(Forecast, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(forecast)

    send_resp(conn, :no_content, "")
  end
end
