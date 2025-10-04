defmodule LangkaOrderManagement.Repo do
  use Ecto.Repo,
    otp_app: :langka_order_management,
    adapter: Ecto.Adapters.Postgres
end
