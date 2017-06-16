defmodule Fairbanks.ApiStatusView do
  use Fairbanks.Web, :view

  def render("index.json", %{status: status}) do
    %{status: status}
  end

end
