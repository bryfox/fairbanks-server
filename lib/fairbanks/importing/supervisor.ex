defmodule Fairbanks.Importing.Supervisor do
  use Supervisor
  alias Fairbanks.Importing

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    import Supervisor.Spec

    children = [
      worker(Importing.Coordinator, [])
    ]
    supervise(children, [strategy: :one_for_one, name: Importing.Supervisor])
  end

end
