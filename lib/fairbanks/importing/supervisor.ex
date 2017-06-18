defmodule Fairbanks.Importing.Supervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    import Supervisor.Spec

    children = [
      # TODO: get rid of :temporary
      worker(Fairbanks.Importing.Coordinator, [], restart: :temporary)
    ]
    supervise(children, [strategy: :one_for_one, name: Fairbanks.Importing.Supervisor])
  end

end
