defmodule LangkaOrderManagementWeb.Router do
  use LangkaOrderManagementWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug LangkaOrderManagementWeb.AuthPlug
  end

  scope "/api/user", LangkaOrderManagementWeb do
    pipe_through :api

    post "/register", AuthController, :register
    post "/login", AuthController, :login
    post "/logout", AuthController, :logout
    post "/refresh", AuthController, :refresh
  end

  # Enable Swoosh mailbox preview in development
  if Application.compile_env(:langka_order_management, :dev_routes) do

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
