defmodule Fairbanks.Eastern do
  @moduledoc """
  Fairbanks time is Eastern.
  This module enables conversion from UTC DateTimes to Eastern (EST/EDT) dates.

  See Fairbanks.Timestamp, which currently provides a higher-level interface for
  getting a local "today".
  """
  require Logger

  @tz "America/New_York"

  def date_from_datetime(datetime) do
    DateTime.to_unix(datetime) + current_utc_offset_seconds(datetime)
    |> DateTime.from_unix!
    |> DateTime.to_date
  end

  ###########################
  # Helpers
  ###########################

  # Return the first period from tzdata, if any exist. In the case of two results,
  # we'll ignore the transition and take the first
  defp current_utc_offset_seconds(datetime) do
    datetime_to_gregorian_seconds(datetime)
    Tzdata.periods_for_time(@tz, datetime_to_gregorian_seconds(datetime), :utc)
    |> List.first
    |> current_utc_offset
  end

  # return the current UTC time expressed as UTC seconds (integer)
  defp datetime_to_gregorian_seconds(datetime) do
    :calendar.datetime_to_gregorian_seconds(to_erlang_datetime(datetime))
  end

  defp to_erlang_datetime(%DateTime{year: yy, month: mm, day: dd, hour: h, minute: m, second: s}) do
    {{yy, mm, dd}, {h, m, s}}
  end

  # Return the number of seconds offset from UTC.
  # We're just dealing with Eastern time, so it's either -4 or -5 hours.
  defp current_utc_offset(%{std_off: std_off, utc_off: utc_off}) do
    std_off + utc_off
  end

  # Unexpected case. Eastern time should never lack TZ data, but just in case,
  # default to EST.
  defp current_utc_offset(nil) do
    Logger.warn("Tzdata is missing zone data for current time.")
    -5 * 60 * 60
  end

end
