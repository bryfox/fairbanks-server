# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :fairbanks,
  ecto_repos: [Fairbanks.Repo],
  user_agent: {:system, "FAIRBANKS_USER_AGENT"},
  data_feed_url: {:system, "FAIRBANKS_FEED_URL"}

config :fairbanks, Fairbanks.Importing,
  autostart: true

# Configures the endpoint
config :fairbanks, FairbanksWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "6ip2YbzyllCoge7nDgiCLFIqpPnJ0z3MRFw01yCC395d2rVS5ThebIo5cXcwU0Qf",
  render_errors: [view: FairbanksWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Fairbanks.PubSub,
           adapter: Phoenix.PubSub.PG2]


# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
