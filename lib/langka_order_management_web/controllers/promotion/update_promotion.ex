defmodule LangkaOrderManagementWeb.UpdatePromotion do
  alias LangkaOrderManagement.Promotion
  alias LangkaOrderManagementWeb.ControllerUtils

  def rules(_) do
    %{
      "id" => [required: true, nullable: false, cast: :integer, type: :integer],
      "transaction_count_to_get_discount" => [required: false, nullable: true, cast: :integer, type: :integer, min: 0],
      "discount_as_percent" => [required: false, nullable: true, cast: :float, type: :float, min: 0.1]
    }
  end

  def perform(conn, %{"id" => id} = args) do
    with promotion when not is_nil(promotion) <- Promotion.get_promotion(id),
         false <- Promotion.promotion_used?(id),
         {:ok, updated_promotion} <- Promotion.update_promotion(promotion, args)
    do
      conn
      |> Phoenix.Controller.put_view(__MODULE__.View)
      |> Phoenix.Controller.render("update_promotion.json", data: updated_promotion)
    else
      true ->
        ControllerUtils.render_error(conn, 422, "422.json", "cannot update a promotion once used")

      nil ->
        ControllerUtils.render_error(conn, 404, "404.json", "promotion not found", "")

      {:error, cs} ->
        conn
        |> Plug.Conn.put_status(422)
        |> Phoenix.Controller.put_view(LangkaOrderManagementWeb.ErrorJSON)
        |> Phoenix.Controller.render("422.json", %{error: cs})
    end
  end

  defmodule View do
    def render("update_promotion.json", %{data: promotion}) do
      %{
        id: promotion.id,
        transaction_count_to_get_discount: promotion.transaction_count_to_get_discount,
        discount_as_percent: promotion.discount_as_percent,
        inserted_at: promotion.inserted_at
      }
    end
  end
end
