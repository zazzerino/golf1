defmodule GolfWeb.Router do
  use GolfWeb, :router
  import GolfWeb.Auth, only: [put_user_token: 2]

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {GolfWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_user_token
  end

  scope "/", GolfWeb do
    pipe_through :browser

    live_session :default, on_mount: GolfWeb.Auth do
      live "/", HomeLive
      live "/user", UserLive
      live "/game/:id", GameLive
      live "/lobby/:id", LobbyLive
    end
  end

  # pipeline :api do
  #   plug :accepts, ["json"]
  # end

  # Other scopes may use custom stacks.
  # scope "/api", GolfWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:golf, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: GolfWeb.Telemetry
    end
  end
end
