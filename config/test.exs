use Mix.Config

config :fairbanks, Fairbanks.Importing,
  autostart: false

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :fairbanks, FairbanksWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :fairbanks, Fairbanks.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "fairbanksdev",
  password: "fairbanksdev",
  database: "fairbanks_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
