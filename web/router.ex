defmodule Fairbanks.Router do
  use Fairbanks.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Fairbanks do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  scope "/api", Fairbanks do
    pipe_through :api

    scope "/v1" do
      get "/", ApiStatusController, :index
      get "/forecasts/today", ForecastController, :show_today
      resources "/forecasts", ForecastController, except: [:new, :edit]
    end
  end
end
