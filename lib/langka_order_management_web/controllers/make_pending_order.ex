defmodule LangkaOrderManagementWeb.MakePendingOrder do
  alias LangkaOrderManagement.{Account, Telegram, SeatingTable}
  alias LangkaOrderManagementWeb.TransactionStream
  alias LangkaOrderManagementWeb.ControllerUtils

  @allowed_sugar_levels [0, 25, 50, 75, 100, 125]
  @allowed_ice_levels ["no ice", "less ice", "normal ice"]

  def rules(_) do
    %{
      "name" => [required: true, nullable: false, type: :string],
      "phone_number" => [required: true, nullable: false, custom: &ControllerUtils.validate_phone_number/1],
      "products_orders" => [required: true, nullable: false, type: :list,
        list: [
          required: true,
          type: :map,
          map: %{
            "product_id" => [required: true, type: :integer, cast: :integer, min: 1],
            "quantity" => [required: true, cast: :integer, type: :integer, min: 1],
            "sugar_level" => [required: false, nullable: true, cast: :integer, custom: &__MODULE__.validate_sugar_level/1],
            "ice_level" => [required: false, nullable: true, type: :string, custom: &__MODULE__.validate_ice_level/1],
            "order_note" => [required: false, nullable: true, type: :string]
          }
        ]
      ],
      "invoice_id" => [required: false, nullable: true, type: :string],
      "seating_table_id" => [required: true, nullable: false, cast: :integer, type: :integer, min: 1]
    }
  end

  def perform(conn, args) do
    with false <- SeatingTable.pending_order_table_limit(args["seating_table_id"]),
         {:ok, %{pending_transaction: transaction, products_orders: products_orders} = multi_res} when is_map(multi_res) <- Account.make_pending_order(args),
         {:ok, _message} <- Telegram.send_order_payload_to_channel(args["name"], args["phone_number"], transaction, products_orders)
        do
          TransactionStream.publish_event(transaction.id, :queued, %{
            status: "pending",
            message: "Your order is in queue",
            transaction_id: transaction.id
          })

          conn
          |> Phoenix.Controller.put_view(__MODULE__.View)
          |> Phoenix.Controller.render("make_pending_order.json", data: {transaction, products_orders})

        else
          true ->
            conn
            |> Plug.Conn.put_status(:bad_request)
            |> Phoenix.Controller.put_view(LangkaOrderManagementWeb.ErrorJSON)
            |> Phoenix.Controller.render("400.json", %{error: :pending_order_limit_reached, message: "The table has reached the pending order limit of 3. Please wait until one of the pending orders is completed."})

          {:error, step, reason, _changes} ->
            conn
            |> Plug.Conn.put_status(:internal_server_error)
            |> Phoenix.Controller.put_view(LangkaOrderManagementWeb.ErrorJSON)
            |> Phoenix.Controller.render("500.json", %{error: :"#{step}", message: "#{inspect(reason)}"})

          error ->
            conn
            |> Plug.Conn.put_status(:internal_server_error)
            |> Phoenix.Controller.put_view(LangkaOrderManagementWeb.ErrorJSON)
            |> Phoenix.Controller.render("500.json", %{error: :unexpected_error_occurred, message: "#{inspect(error)}"})
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
        bill_price_before_discount_as_usd: trx.bill_price_before_discount_as_usd,
        bill_price_after_discount_as_usd: trx.bill_price_after_discount_as_usd,
        discount_amount_as_usd: trx.discount_amount_as_usd,
        discount_as_percent_applied: trx.discount_as_percent_applied,
        promotion_apply_id: trx.promotion_apply_id,
        products_orders: Enum.map(po, & %{
          id: &1["product_detail"].id,
          quantity: &1["quantity"],
          name: &1["product_detail"].name,
          sugar_level: &1["sugar_level"],
          ice_level: &1["ice_level"],
          order_note: &1["order_note"]
        })
      }
    end
  end

  def validate_sugar_level(%{value: nil}), do: Validate.Validator.success(nil)

  def validate_sugar_level(%{value: sugar_level}) when sugar_level in @allowed_sugar_levels,
    do: Validate.Validator.success(sugar_level)

  def validate_sugar_level(%{value: _}),
    do: Validate.Validator.error("sugar_level must be one of: 0, 25, 50, 75, 100, 125")

  def validate_ice_level(%{value: nil}), do: Validate.Validator.success(nil)

  def validate_ice_level(%{value: ice_level}) when ice_level in @allowed_ice_levels,
    do: Validate.Validator.success(ice_level)

  def validate_ice_level(%{value: _}),
    do: Validate.Validator.error("ice_level must be one of: no ice, less ice, normal ice")
end
