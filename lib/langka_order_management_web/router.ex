defmodule LangkaOrderManagementWeb.Router do
  use LangkaOrderManagementWeb, :router
  alias LangkaOrderManagementWeb.FormRequest

  pipeline :api do
    plug :accepts, ["json", "sse"]
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
    pipe_through [:api]

    get "/list_transaction", FormRequest, LangkaOrderManagementWeb.ListTransaction
    get "/transaction/:id", FormRequest, LangkaOrderManagementWeb.GetTransaction
    patch "/transactions/:id/invoice_id", FormRequest, LangkaOrderManagementWeb.UpdateCompletedTransactionInvoice
    get "/list_table_transaction", FormRequest, LangkaOrderManagementWeb.ListTableTransaction
    get "/list_user", FormRequest, LangkaOrderManagementWeb.ListUser
    get "/metrics/product_monthly", FormRequest, LangkaOrderManagementWeb.ListProductMonthlyMetric
    get "/metrics/table_monthly", FormRequest, LangkaOrderManagementWeb.ListTableMonthlyMetric
    get "/metrics/employee_monthly", FormRequest, LangkaOrderManagementWeb.ListEmployeeMonthlyMetric
    get "/metrics/promotion_usage", FormRequest, LangkaOrderManagementWeb.ListPromotionUsageMetric
    get "/metrics/promotion_progression", FormRequest, LangkaOrderManagementWeb.ListPromotionProgressionMetric

    get "/export_transaction", FormRequest, LangkaOrderManagementWeb.ExportTransaction
    get "/export_user", FormRequest, LangkaOrderManagementWeb.ExportUser

    scope "/products" do
      post "/", FormRequest, LangkaOrderManagementWeb.CreateProduct
      get "/:id", FormRequest, LangkaOrderManagementWeb.GetProduct
      patch "/:id", FormRequest, LangkaOrderManagementWeb.UpdateProduct
      delete "/:id", FormRequest, LangkaOrderManagementWeb.DeleteProduct
    end

    scope "/categories" do
      post "/", FormRequest, LangkaOrderManagementWeb.CreateCategory
    end

    scope "/seating_tables" do
      post "/", FormRequest, LangkaOrderManagementWeb.CreateSeatingTable
      get "/", FormRequest, LangkaOrderManagementWeb.ListSeatingTable
      get "/:id", FormRequest, LangkaOrderManagementWeb.GetSeatingTable
      patch "/:id", FormRequest, LangkaOrderManagementWeb.UpdateSeatingTable
      delete "/:id", FormRequest, LangkaOrderManagementWeb.DeleteSeatingTable
    end

    scope "/promotions" do
      get "/", FormRequest, LangkaOrderManagementWeb.ListPromotion
      patch "/:id", FormRequest, LangkaOrderManagementWeb.UpdatePromotion
      get "/:id", FormRequest, LangkaOrderManagementWeb.GetPromotion
      delete "/:id", FormRequest, LangkaOrderManagementWeb.DeletePromotion
      post "/", FormRequest, LangkaOrderManagementWeb.CreatePromotion
    end

    scope "/employees" do
      post "/", FormRequest, LangkaOrderManagementWeb.CreateEmployee
      get "/", FormRequest, LangkaOrderManagementWeb.ListEmployee
      get "/:id", FormRequest, LangkaOrderManagementWeb.GetEmployee
      patch "/:id", FormRequest, LangkaOrderManagementWeb.UpdateEmployee
      delete "/:id", FormRequest, LangkaOrderManagementWeb.DeleteEmployee
    end

    scope "/inventories" do
      post "/", FormRequest, LangkaOrderManagementWeb.CreateInventory
      get "/", FormRequest, LangkaOrderManagementWeb.ListInventory
      get "/:id", FormRequest, LangkaOrderManagementWeb.GetInventory
      patch "/:id", FormRequest, LangkaOrderManagementWeb.UpdateInventory
      delete "/:id", FormRequest, LangkaOrderManagementWeb.DeleteInventory

      post "/:inventory_id/movements", FormRequest, LangkaOrderManagementWeb.CreateInventoryMovement
      get "/:inventory_id/movements", FormRequest, LangkaOrderManagementWeb.ListInventoryMovement
    end
  end

  scope "/api/auth", LangkaOrderManagementWeb do
    pipe_through :api

    post "/register", AuthController, :register
    post "/login", AuthController, :login
  end

  scope "/api/telegram_integration" do
    pipe_through :api

    post "/webhook_handler", FormRequest, LangkaOrderManagementWeb.TelegramWebhook
  end

  scope "/api" do
    pipe_through :api

    scope "/products" do
      get "/", FormRequest, LangkaOrderManagementWeb.ListProduct
    end

    scope "/categories" do
      get "/", FormRequest, LangkaOrderManagementWeb.ListProductCategory
    end

    post "/order", FormRequest, LangkaOrderManagementWeb.MakePendingOrder

    get "/promotion", FormRequest, LangkaOrderManagementWeb.GetActivePromotion
    get "/promotion/preview", FormRequest, LangkaOrderManagementWeb.GetPromotionPreview

    get "/transaction/stream", LangkaOrderManagementWeb.TransactionStream, :stream

    post "/public_bucket_asset", FormRequest, LangkaOrderManagementWeb.GetPublicAsset
  end

  # Enable Swoosh mailbox preview in development
  if Application.compile_env(:langka_order_management, :dev_routes) do

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
