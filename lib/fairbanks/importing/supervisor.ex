defmodule Fairbanks.Importing.Supervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    import Supervisor.Spec

    children = [
      worker(Fairbanks.Importing.Coordinator, [])
    ]
    supervise(children, [strategy: :one_for_one, name: Fairbanks.Importing.Supervisor])
  end

end
