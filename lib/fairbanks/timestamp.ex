defmodule Fairbanks.Timestamp do
  @moduledoc """
  Provides an interface for custom date formatting from the source RSS feed.
  """
  @behaviour Ecto.Type
  @months %{jan: 1, feb: 2, mar: 3, apr: 4, may: 5, jun: 6, jul: 7, aug: 8, sep: 9, oct: 10, nov: 11, dec: 12}

  @doc """
  Return today's date in Eastern (EST or EDT, as appropriate) time.
  """
  @spec today() :: Date
  def today do
    Fairbanks.Eastern.date_from_datetime(DateTime.utc_now)
  end

  ###########################
  # Ecto.Type callbacks
  ###########################

  @impl Ecto.Type
  def type, do: :date

  # Cast to a Date from the string input
  # This callback is called on external input -- e.g. from controller action
  # Expected Input: string fetched from the <pubDate> in the RSS data source
  # (e.g. "Fri, 16 Jun 2017 00:00:00 -0400")
  # `dump/1` is able to convert the returned
  # value back into an Ecto native type.
  @impl Ecto.Type
  @spec cast(String) :: {:ok, Date} | :error
  def cast(string) when is_binary(string) do
    case to_date(string) do
      {:ok, date} -> {:ok, date}
      {:error, _} -> :error
    end
  end

  @spec cast(Date) :: {:ok, Date} | :error
  def cast(%Date{} = date), do:
    {:ok, date}

  def cast(_), do: :error

  # When loading data from the database,
  # From tuple back to date...
  # See load_date in ecto/type.ex
  @impl Ecto.Type
  @spec load(Date) :: {:ok, Date} | :error
  def load(%Date{} = date), do: {:ok, date}

  @impl Ecto.Type
  def load(_), do: :error

  # Dumps the given term into an Ecto native type for DB insertion
  # (The Date argument, used by the app, has already been cast from a String.)
  # See dump_date in ecto/type.ex
  @impl Ecto.Type
  @spec dump(Date) :: {:ok, tuple} | :error
  def dump(%Date{year: year, month: month, day: day}), do:
    {:ok, %Date{year: year, month: month, day: day}}
  def dump(_), do: :error

  @impl Ecto.Type
  def equal?(nil, nil), do: true
  def equal?(nil, _), do: false
  def equal?(_, nil), do: false
  def equal?(a, b),
    do: a.equal(b)

  @impl Ecto.Type
  def embed_as(_), do: :self

  ###########################
  # Helpers
  ###########################

  # Example input: "Fri, 16 Jun 2017 00:00:00 -0400"
  @spec to_date(String) :: { :ok, Date } | { :error, String }
  defp to_date(timestamp) when is_binary(timestamp)  do
    case String.split(timestamp) do
      [_, dd, mm, yyyy | _] ->
        Date.new(String.to_integer(yyyy), @months[key(mm)], String.to_integer(dd))
      _ ->
        {:error, :invalid_format}
    end
  end

  defp key(month_name) when is_binary(month_name) do
    month_name
    |> String.downcase
    |> String.slice(0..2)
    |> String.to_atom
  end

end
