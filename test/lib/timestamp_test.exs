defmodule Fairbanks.TimestampTest do
  use ExUnit.Case

  alias Fairbanks.Timestamp

  test "returns the correct date" do
    {:ok, date} = Timestamp.cast("Thu, 15 Jun 2017 00:00:00 -0400")
    assert ~D[2017-06-15] == date
  end

  test "is resilient to missing times" do
    {:ok, date} = Timestamp.cast("Thu, 15 Jun 2017")
    assert ~D[2017-06-15] == date
  end

  test "is resilient to month names" do
    {:ok, date} = Timestamp.cast("Thu, 15 June 2017")
    assert ~D[2017-06-15] == date
  end

  test "returns :error with unexpected date format" do
    assert :error = Timestamp.cast("15 June 2017")
  end

  test "returns :error with date out of range" do
    assert :error = Timestamp.cast("Thu, 29 Feb 2017")
  end

  test "returns :error with unexpected input" do
    assert :error = Timestamp.cast("not a date")
  end

  test "returns :error with empty input" do
    assert :error = Timestamp.cast("")
  end

  test "allows date inputs to cast" do
    {:ok, date} = Timestamp.cast(~D[2017-06-15])
    assert ~D[2017-06-15] == date
  end

end
