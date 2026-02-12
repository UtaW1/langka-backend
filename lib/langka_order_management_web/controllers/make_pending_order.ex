defmodule LangkaOrderManagementWeb.MakePendingOrder do
  alias LangkaOrderManagement.{Account, Telegram}

  def rules(_) do
    %{
      "user_id" => [required: false, nullable: true, type: :string],
      "products_orders" => [required: true, nullable: false, type: :list,
        list: [
          required: true,
          type: :map,
          map: %{
            "product_id" => [required: true, type: :integer, cast: :integer, min: 1],
            "quantity" => [required: true, cast: :integer, type: :integer, min: 1]
          }
        ]
      ],
      "invoice_id" => [required: false, nullable: true, type: :string],
      "table_number" => [required: true, nullable: false, cast: :string, type: :string]
    }
  end

  def perform(conn, args) do
    with {:ok, %{pending_transaction: transaction, products_orders: products_orders} = multi_res} when is_map(multi_res) <- Account.make_pending_order(args),
         {:ok, _message} <- Telegram.send_order_payload_to_channel(args["user_id"], transaction, products_orders)
        do
          conn
          |> Phoenix.Controller.put_view(__MODULE__.View)
          |> Phoenix.Controller.render("make_pending_order.json", data: {transaction, products_orders})

        else
          {:error, step, reason, _changes} ->
            conn
            |> Plug.Conn.put_status(:internal_server_error)
            |> Phoenix.Controller.put_view(LangkaOrderManagementWeb.ErrorJSON)
            |> Phoenix.Controller.render("500.json", %{error: :"#{step}", message: "#{inspect(reason)}"})

          error ->
            conn
            |> Plug.Conn.put_status(:internal_server_error)
            |> Phoenix.Controller.put_view(LangkaOrderManagementWeb.ErrorJSON)
            |> Phoenix.Controller.render("500.json", %{error: :unepxcted_error_occured, message: "#{inspect(error)}"})
        end
  end

  defmodule View do
    def render("make_pending_order.json", %{data: {trx, po}}) do
      %{
        id: trx.id,
        inserted_at: trx.inserted_at,
        invoice_id: trx.invoice_id,
        user_id: trx.user_id,
        bill_price_as_usd: trx.bill_price_as_usd,
        promotion_apply_id: trx.promotion_apply_id,
        products_orders: Enum.map(po, & %{
          id: &1["product_detail"].id,
          quantity: &1["quantity"],
          name: &1["product_detail"].name
        })
      }
    end
  end
end
