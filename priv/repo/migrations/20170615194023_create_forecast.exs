defmodule Fairbanks.Repo.Migrations.CreateForecast do
  use Ecto.Migration

  def change do
    create table(:forecasts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :text
      add :uri, :text
      add :rss_timestamp, :text
      add :description, :text

      timestamps(inserted_at: :created_at, updated_at: :updated_at, type: :timestamptz)
    end

    create unique_index(:forecasts, [:uri])
    create index(:forecasts, [:created_at, :updated_at])
  end
end
