defmodule LangkaOrderManagementWeb.Router do
  use LangkaOrderManagementWeb, :router
  alias LangkaOrderManagementWeb.FormRequest

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

  scope "/api/admin" do
    pipe_through [:api, :admin]

    get "/list_transaction", FormRequest, LangkaOrderManagementWeb.ListTransaction
    get "/list_user", FormRequest, LangkaOrderManagementWeb.ListUser

    scope "/products" do
      post "/", FormRequest, LangkaOrderManagementWeb.CreateProduct

      post "/category", FormRequest, LangkaOrderManagementWeb.CreateCategory
      get "/category", FormRequest, LangkaOrderManagementWeb.ListProductCategory
    end
  end

  scope "/api/auth", LangkaOrderManagementWeb do
    pipe_through :api

    post "/register", AuthController, :register
    post "/login", AuthController, :login
  end

  scope "/telegram_integration" do
    pipe_through :api

    post "/webhook_handler", FormRequest, LangkaOrderManagementWeb.TelegramWebhook
  end

  scope "/api" do
    pipe_through :api

    scope "/products" do
      get "/", FormRequest, LangkaOrderManagementWeb.ListProduct
    end

    post "/order", FormRequest, LangkaOrderManagementWeb.MakePendingOrder
  end

  # Enable Swoosh mailbox preview in development
  if Application.compile_env(:langka_order_management, :dev_routes) do

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
