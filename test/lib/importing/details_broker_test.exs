defmodule Fairbanks.Importing.DetailsBrokerTest do
  alias Fairbanks.Importing.DetailsBroker
  use ExUnit.Case

  @soundcloud_iframe_src "https://w.soundcloud.com/player/?visual=false&url=https%3A%2F%2Fapi.soundcloud.com%2Ftracks%2F328230856&show_artwork=false&maxwidth=400px&maxheight=166px&show_comments=false&color=F7941E"

  ###########################
  # Scraping format tests
  ###########################

  test "soundcloud ID is extracted" do
    assert "328230856" == DetailsBroker.soundcloud_src_to_id(@soundcloud_iframe_src)
  end

end
