defmodule FairbanksWeb.ApiStatusController do
  use Fairbanks.Web, :controller

  def index(conn, _params) do
    render(conn, "index.json", status: "ok")
  end
end