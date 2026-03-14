defmodule LangkaOrderManagement.Telegram do
  def telegram_channel_id() do
    :langka_order_management
    |> Application.get_env(:telegram_integration)
    |> Keyword.get(:channel_id)
  end

  def telegram_token() do
    Application.get_env(:nadia, :token)
  end

  def send_order_payload_to_channel(customer_name, phone_number, transaction, products_orders) do
    items_list =
      Enum.map_join(products_orders, "\n", fn product_order ->
        product_name = product_order["product_detail"].name
        quantity = product_order["quantity"]

        customizations =
          [
            if(product_order["sugar_level"], do: "sugar: #{product_order["sugar_level"]}%", else: nil),
            if(product_order["ice_level"], do: "ice: #{product_order["ice_level"]}", else: nil),
            if(product_order["order_note"], do: "note: #{product_order["order_note"]}", else: nil)
          ]
          |> Enum.reject(&is_nil/1)

        item_line = "- #{product_name} (x#{quantity})"

        if customizations == [] do
          item_line
        else
          item_line <> "\n  customizations: " <> Enum.join(customizations, " | ")
        end
      end)

    message = """
      *NEW ORDER RECEIVED!*
      Customer: #{customer_name} (#{phone_number})
      Table: #{transaction.seating_table_id}
      Items:
      #{items_list}
      Total: $#{transaction.bill_price_as_usd}
    """

    buttons = [
      [
        %{text: "Complete", callback_data: "transaction:complete:#{transaction.id}"},
        %{text: "Cancel", callback_data: "transaction:cancel:#{transaction.id}"}
      ]
    ]

    Nadia.send_message(telegram_channel_id(), message, [
      parse_mode: "Markdown",
      reply_markup: %{inline_keyboard: buttons}
    ])
  end
end
