defmodule Fairbanks.Repo.Migrations.CreateForecast do
  use Ecto.Migration

  def change do
    create table(:forecasts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :text
      add :permalink, :text
      add :soundcloud_url, :text, null: true
      add :soundcloud_id, :text, null: true
      add :today_desc, :text, null: true
      add :tonight_desc, :text, null: true
      add :tomorrow_desc, :text, null: true
      add :tomorrow_night_desc, :text, null: true

      timestamps(inserted_at: :created_at, updated_at: :updated_at, type: :utc_datetime)
    end

    create unique_index(:forecasts, [:permalink])
    create index(:forecasts, [:created_at, :updated_at])
  end
end
