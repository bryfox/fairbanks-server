defmodule FairbanksWeb.PageController do
  use Fairbanks.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
