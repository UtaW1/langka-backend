defmodule LangkaOrderManagementWeb.GetActivePromotion do
  alias LangkaOrderManagement.Promotion

  def rules(_) do
    %{}
  end

  def perform(conn, _) do
    with promotion when not is_nil(promotion) <- Promotion.get_latest_active_promotion_for_transaction() do
      conn
      |> Phoenix.Controller.put_view(__MODULE__.View)
      |> Phoenix.Controller.render("create_promotion.json", data: promotion)
    else
      nil ->
        conn
        |> Phoenix.Controller.put_view(__MODULE__.View)
        |> Phoenix.Controller.render("create_promotion.json", data: nil)

      {:error, reason} ->
        LangkaOrderManagementWeb.ControllerUtils.render_error(conn, 500, "500.json", "unexpcted error", "#{Kernel.inspect(reason)}")
    end
  end

  defmodule View do
    def render("create_promotion.json", %{data: nil}) do
      %{}
    end

    def render("create_promotion.json", %{data: promotion}) do
      %{
        id: promotion.id,
        transaction_count_to_get_discount: promotion.transaction_count_to_get_discount,
        discount_as_percent: promotion.discount_as_percent,
        inserted_at: promotion.inserted_at
      }
    end
  end
end
