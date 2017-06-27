defmodule Fairbanks.Forecast do
  use Fairbanks.Web, :model

  alias Ecto.Query
  alias Fairbanks.Repo

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "forecasts" do
    field :title, :string
    field :uri, :string
    field :description, :string
    field :publication_date, Fairbanks.Timestamp

    field :details_processed, :boolean
    field :soundcloud_id, :string
    field :detailed_summary, :map
    field :extended_summary, :map
    field :recreational_summary, :map

    timestamps(inserted_at: :created_at, updated_at: :updated_at, type: :utc_datetime)
  end

  @doc """
  Map (jsonb) fields must use this as the root key for any data;
  source data may be represented as arrays, but we will always store & return a JSON object.
  """
  # TODO: define a custom type that casts automatically
  def summary_key, do: :node

  @doc """
  Use this to determine whether details still need to be downloaded for a forecast.
  Checking one of the detail data fields directly may be incorrect if updating was aborted
  because of an unrecoverable error.
  The soundcloud_id is considered to be an additional detail needed; retries should happen
  when details have been processed but we're still missing audio.
  """
  def needs_details?(%__MODULE__{} = forecast), do:
    forecast.details_processed != true || forecast.soundcloud_id == nil

  @doc """
  Return true if a forecast for this date is needed;
  false if it has already been created.
  This provides an interface for an importer to determine if a uniqueness
  constraint would be violated without handling insertion errors.
  Duplicate errors is a common case when dealing with an RSS feed of forecasts.
  """
  @spec needed_for_date?(Date.t | Ecto.Changeset.t) :: boolean
  def needed_for_date?(%Ecto.Changeset{changes: changes}), do: needed_for_date?(changes.publication_date)
  def needed_for_date?(%Date{} = date) do
    __MODULE__
    |> Query.where([f], f.publication_date == ^date)
    |> Query.select([f], f.id)
    |> Repo.one
    |> is_nil
  end

  @doc """
  The most recent forecast in the DB
  """
  @spec latest() :: Forecast.t | nil
  def latest do
    __MODULE__
    |> Query.first(desc: :created_at)
    |> Repo.one
  end

  def for_today do
    today = Fairbanks.Timestamp.today()
    __MODULE__
    |> Query.where(publication_date: ^today)
    |> Query.first(desc: :created_at)
    |> Repo.one
  end

  @doc """
  Returns true if the latest saved forecast is from today,
  or if no saved forecast is found.
  """
  @spec have_latest?() :: boolean | :error
  def have_latest?, do: have_latest? latest()

  defp have_latest?(%{publication_date: _} = forecast), do: not outdated?(forecast)
  defp have_latest?(nil), do: false
  defp have_latest?(_), do: :error

  # Returns true if the given forecast's publication date is before today (UTC).
  # @spec outdated?(Forecast.t) :: boolean | :error
  defp outdated?(%{publication_date: nil}), do: true
  defp outdated?(%{publication_date: publication_date}), do: publication_date < Date.utc_today()

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:id, :title, :uri, :description, :publication_date, :soundcloud_id, :detailed_summary, :extended_summary, :recreational_summary, :details_processed])
    |> validate_required([:title, :uri, :description, :publication_date])
    |> unique_constraint(:uri) # TODO: test
  end

end
