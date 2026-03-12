defmodule LangkaOrderManagementWeb.GetPromotion do
  alias LangkaOrderManagement.Promotion

  def rules(_) do
    %{
      "id" => [required: true, nullable: false, cast: :integer, type: :integer]
    }
  end

  def perform(conn, %{"id" => id}) do
    with promotion when not is_nil(promotion) <- Promotion.get_promotion(id)
      do
        conn
        |> Phoenix.Controller.put_view(__MODULE__.View)
        |> Phoenix.Controller.render("get_promotion.json", data: promotion)
      else
        nil ->
          conn
          |> Plug.Conn.put_status(404)
          |> Phoenix.Controller.put_view(LangkaOrderManagementWeb.ErrorJSON)
          |> Phoenix.Controller.render("404.json", %{error: {"resource not found", "promotion does not exist"}})
    end
  end

  defmodule View do
    def render("promotion.json", %{data: promotion}) do
      %{
        id: promotion.id,
        transaction_count_to_get_discount: promotion.transaction_count_to_get_discount,
        discount_as_percent: promotion.discount_as_percent,
        status: promotion.status
      }
    end
  end
end
