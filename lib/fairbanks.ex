defmodule Fairbanks do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(Fairbanks.Repo, []),
      # Start the endpoint when the application starts
      supervisor(Fairbanks.Endpoint, [])
    ]

    # Unless disabled by config, also supervise workers for periodic data fetching
    children = if run_importers?(), do: children ++ [supervisor(Fairbanks.Importing.Supervisor, [])], else: children

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Fairbanks.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Fairbanks.Endpoint.config_change(changed, removed)
    :ok
  end

  defp run_importers?, do:
    Application.get_env(:fairbanks, Fairbanks.Importing)[:autostart] == true

end
