defmodule LangkaOrderManagementWeb.CreatePromotion do
  alias LangkaOrderManagement.Promotion

  def rules(_) do
    %{
      "transaction_count_to_get_discount" => [required: true, nullable: false, cast: :integer, type: :integer, min: 0],
      "discount_as_percent" => [required: true, nullable: false, cast: :float, type: :float, min: 0.1]
    }
  end

  def perform(conn, args) do
    with {:ok, promotion} <- Promotion.create_promotion(args) do
      conn
      |> Phoenix.Controller.put_view(__MODULE__.View)
      |> Phoenix.Controller.render("create_promotion.json", data: promotion)
    else
      {:error, reason} ->
        LangkaOrderManagementWeb.ControllerUtils.render_error(conn, 500, "500.json", "unexpcted error", "#{Kernel.inspect(reason)}")
    end
  end

  defmodule View do
    def render("create_promotion.json", %{data: promotion}) do
      %{
        id: promotion.id,
        transaction_count_to_get_discount: promotion.transaction_count_to_get_discount,
        discount_as_percent: promotion.discount_as_percent,
        status: promotion.status,
        inserted_at: promotion.inserted_at
      }
    end
  end
end
