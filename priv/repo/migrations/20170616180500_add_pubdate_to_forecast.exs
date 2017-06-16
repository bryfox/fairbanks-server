defmodule Fairbanks.Repo.Migrations.AddPubdateToForecast do
  use Ecto.Migration

  def up do
    alter table(:forecasts) do
      remove :rss_timestamp
      add :publication_date, :date
    end

    create index(:forecasts, [:publication_date])
    drop index(:forecasts, [:created_at, :updated_at])
  end

  def down do
    alter table(:forecasts) do
      add :rss_timestamp, :text
      remove :publication_date
    end

    create index(:forecasts, [:created_at, :updated_at])
  end

end
