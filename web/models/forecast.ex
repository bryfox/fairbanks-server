defmodule Fairbanks.Forecast do
  use Fairbanks.Web, :model

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
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:id, :title, :uri, :description, :publication_date])
    |> validate_required([:title, :uri, :description, :publication_date])
    |> unique_constraint(:uri) # TODO: test
  end

end
