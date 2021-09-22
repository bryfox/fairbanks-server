defmodule Fairbanks.Repo do
  use Ecto.Repo,
    otp_app: :fairbanks,
    adapter: Ecto.Adapters.Postgres
end
