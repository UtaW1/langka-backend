defmodule LangkaOrderManagementWeb.Router do
  use LangkaOrderManagementWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug LangkaOrderManagementWeb.AuthPlug
  end

  pipeline :user do
    plug LangkaOrderManagementWeb.RequireAuth
  end

  pipeline :admin do
    plug LangkaOrderManagementWeb.RequireAdmin
  end

  scope "/api/user", LangkaOrderManagementWeb do
    pipe_through [:api, :user]

    post "/refresh", AuthController, :refresh
    post "/logout", AuthController, :logout
  end

  scope "/api", LangkaOrderManagementWeb do
    pipe_through :api

    post "/register", AuthController, :register
    post "/login", AuthController, :login
  end

  # Enable Swoosh mailbox preview in development
  if Application.compile_env(:langka_order_management, :dev_routes) do

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
