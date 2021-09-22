defmodule Mix.Tasks.Fairbanks.Data.Import do
  use Mix.Task

  @shortdoc "Download remote data, save to DB, and exit"
  def run(_) do
    start_repo()
    Fairbanks.Importing.Coordinator.import_once()
    stop_repo()
  end

  defp start_repo do
    Enum.each(
      [
        :postgrex,
        :ecto,
        :ecto_sql,
        :httpoison
      ],
      &Application.ensure_all_started/1
    )
    Fairbanks.Repo.start_link()
  end

  defp stop_repo do
    :init.stop()
  end
end