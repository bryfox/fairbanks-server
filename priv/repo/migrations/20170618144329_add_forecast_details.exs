defmodule Fairbanks.Repo.Migrations.AddForecastDetails do
  use Ecto.Migration

  def up do
    alter table(:forecasts) do
      add :details_processed, :boolean, default: false
      add :soundcloud_id, :text
      add :detailed_summary, :map
      add :extended_summary, :map
      add :recreational_summary, :map
    end
  end

  def down do
    alter table(:forecasts) do
      remove :details_processed
      remove :soundcloud_id
      remove :detailed_summary
      remove :extended_summary
      remove :recreational_summary
    end
  end

end
