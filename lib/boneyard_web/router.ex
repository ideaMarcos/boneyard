defmodule BoneyardWeb.Router do
  use BoneyardWeb, :router
  import Phoenix.LiveView.Router
  import Oban.Web.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BoneyardWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Plug.RequestId
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug Plug.RequestId
  end

  scope "/", BoneyardWeb do
    pipe_through :browser

    live "/", HomeLive
    get "/game/join/:id", GameController, :join
    live "/game/:id/:player_code", GameLive

    oban_dashboard "/oban"
  end

  # Other scopes may use custom stacks.
  # scope "/api", BoneyardWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:boneyard, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: BoneyardWeb.Telemetry
    end
  end
end
