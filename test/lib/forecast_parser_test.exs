defmodule Fairbanks.ForecastParserTest do
  use Fairbanks.ModelCase

  alias Fairbanks.ForecastParser
  alias FairbanksWeb.Forecast

  @attrs %{description: "content", publication_date: ~D[2017-07-06], title: "Daily", uri: "-", id: Ecto.UUID.generate() }
  @soundcloud_iframe_src "https://w.soundcloud.com/player/?visual=false&url=https%3A%2F%2Fapi.soundcloud.com%2Ftracks%2F328230856&show_artwork=false&maxwidth=400px&maxheight=166px&show_comments=false&color=F7941E"

  setup do
    changeset = Forecast.changeset(%Forecast{}, @attrs)
    forecast = Repo.insert! changeset
    mock_file = File.cwd!() <> "/mocks/leading_break.html"
    html = File.read!(mock_file)
    {:ok, forecast: forecast, html: html}
  end

  describe "html_to_changeset/2" do

    test "handles nested content", state do
      changeset = ForecastParser.html_to_changeset(state[:html], state[:forecast])
      assert changeset.valid?
      refute changeset.changes[:detailed_summary] == ""
    end

    test "can be parsed as JSON", state do
      changeset = ForecastParser.html_to_changeset(state[:html], state[:forecast])
      forecast = Repo.update!(changeset)
      assert List.first(forecast.detailed_summary[:node])
    end

    test "handles empty data", state do
      changeset = ForecastParser.html_to_changeset("", state[:forecast])
      assert Repo.update!(changeset)
    end

  end

  describe "soundcloud parsing" do
    test "soundcloud ID is extracted" do
      assert "328230856" == ForecastParser.soundcloud_src_to_id(@soundcloud_iframe_src)
    end
  end

end
