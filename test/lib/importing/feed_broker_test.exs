defmodule Fairbanks.Importing.FeedBrokerTest do
  use ExUnit.Case

  alias Fairbanks.Importing.FeedBroker
  import Mock

  @url "http://fakeurl"
  @test_user_agent "test_user_agent"

  setup do
    # Required Ecto setup, taken from ModelCase
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Fairbanks.Repo)
     Ecto.Adapters.SQL.Sandbox.mode(Fairbanks.Repo, {:shared, self()})

    {:ok, broker} = FeedBroker.start_link(@test_user_agent)
    {:ok, broker: broker}
  end

  test "can parse items", %{broker: broker} do
    mock_file = File.cwd!() <> "/mocks/rss.xml"
    resp = {:ok, %HTTPoison.Response{status_code: 200, body: File.read!(mock_file)}}
    with_mock HTTPoison, [get: fn(_url, _) -> resp end] do
      assert :ok = FeedBroker.import(broker, @url)
    end
  end

  test "ignores an empty feed", %{broker: broker} do
    empty_rss = "<rss></rss>"
    resp = {:ok, %HTTPoison.Response{status_code: 200, body: empty_rss}}
    with_mock HTTPoison, [get: fn(_url, _) -> resp end] do
      assert :ignore = FeedBroker.import(broker, @url)
    end
  end

  test "indicates error when parsing invalid content", %{broker: broker} do
    invalid_rss = ""
    resp = {:ok, %HTTPoison.Response{status_code: 200, body: invalid_rss}}
    with_mock HTTPoison, [get: fn(_url, _) -> resp end] do
      assert :error = FeedBroker.import(broker, @url)
    end
  end

  @tag capture_log: true
  test "indicates error response from server", %{broker: broker} do
    resp = {:error, %HTTPoison.Error{}}
    with_mock HTTPoison, [get: fn(_url, _) -> resp end] do
      assert :error = FeedBroker.import(broker, @url)
    end
  end

  @tag capture_log: true
  test "indicates error if server is down", %{broker: broker} do
    assert :error = FeedBroker.import(broker, "http://localhost:9001")
  end

end
