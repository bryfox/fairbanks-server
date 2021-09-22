defmodule Mix.Tasks.Fairbanks.Data.Import do
  use Mix.Task
  import Mix.Ecto

  @shortdoc "Download remote data, save to DB, and exit"
  def run(_) do
    Application.ensure_all_started(:httpoison)
    Mix.Task.run("app.start")
    Fairbanks.Importing.Coordinator.import_once()
  end
end