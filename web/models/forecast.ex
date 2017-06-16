defmodule Fairbanks.Forecast do
  use Fairbanks.Web, :model

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "forecasts" do
    field :title, :string
    field :permalink, :string
    field :soundcloud_url, :string
    field :soundcloud_id, :string
    field :today_desc, :string
    field :tonight_desc, :string
    field :tomorrow_desc, :string
    field :tomorrow_night_desc, :string

    timestamps(inserted_at: :created_at, updated_at: :updated_at, type: :utc_datetime)
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:id, :title, :permalink, :soundcloud_url, :soundcloud_id, :today_desc, :tonight_desc, :tomorrow_desc, :tomorrow_night_desc])
    |> validate_required([:title, :permalink])
  end
end
