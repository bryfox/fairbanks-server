use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application.
config :fairbanks, FairbanksWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    node: [
      "node_modules/webpack/bin/webpack.js",
      "--mode",
      "development",
      "--watch-stdin",
      cd: Path.expand("../assets", __DIR__)
    ]
  ]

# Watch static and templates for browser reloading.
config :fairbanks, FairbanksWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{lib/fairbanks_web/views/.*(ex)$},
      ~r{lib/fairbanks_web/templates/.*(eex)$}
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Configure your database
# Reminder: `ALTER ROLE fairbanksdev CREATEDB;`
config :fairbanks, Fairbanks.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "fairbanksdev",
  password: "fairbanksdev",
  database: "fairbanks_dev",
  hostname: "localhost",
  pool_size: 10
