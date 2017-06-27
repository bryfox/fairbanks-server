defmodule Fairbanks.EasternTest do
  use ExUnit.Case

  alias Fairbanks.Eastern

  describe "Eastern.date_from_datetime/1" do
    test "returns today" do
      {:ok, now, 0} = DateTime.from_iso8601("2017-06-27T12:00:00Z")
      assert ~D[2017-06-27] = Eastern.date_from_datetime(now)
    end

    test "returns today even when it's tomorrow (UTC)" do
      {:ok, now, 0} = DateTime.from_iso8601("2017-06-28T01:00:00Z")
      assert ~D[2017-06-27] = Eastern.date_from_datetime(now)
    end

    test "returns today even when it's UTC tomorrow: border case before" do
      {:ok, now, 0} = DateTime.from_iso8601("2017-06-28T03:59:59Z")
      assert ~D[2017-06-27] = Eastern.date_from_datetime(now)
    end

    test "returns today even when it's UTC tomorrow: border case after" do
      {:ok, now, 0} = DateTime.from_iso8601("2017-06-28T04:00:00Z")
      assert ~D[2017-06-28] = Eastern.date_from_datetime(now)
    end

    test "returns today even when it's UTC tomorrow: outside of DST" do
      {:ok, now, 0} = DateTime.from_iso8601("2017-01-28T04:00:00Z")
      assert ~D[2017-01-27] = Eastern.date_from_datetime(now)
    end

  end

end
