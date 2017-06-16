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
    timestamps(inserted_at: :created_at, updated_at: :updated_at, type: :utc_datetime)
  end

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
    |> Query.first(:created_at)
    |> Repo.one
  end

  def need_update?

  @doc """
  Returns true if the latest saved forecast is from today,
  or if no saved forecast is found.
  """
  @spec have_latest?() :: boolean | :error
  def have_latest?, do: have_latest? latest()

  defp have_latest?(%{publication_date: publication_date} = forecast), do: not outdated?(forecast)
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
    |> cast(params, [:id, :title, :uri, :description, :publication_date])
    |> validate_required([:title, :uri, :description, :publication_date])
    |> unique_constraint(:uri) # TODO: test
  end

end
