defmodule LangkaOrderManagement.Telegram do
  def telegram_channel_id() do
    :langka_order_management
    |> Application.get_env(:telegram_integration)
    |> Keyword.get(:channel_id)
  end

  def telegram_token() do
    :langka_order_management
    |> Application.get_env(:nadia)
    |> Keyword.get(:token)
  end

  def send_order_payload_to_channel(user_id, transaction, products_orders) do
    items_list = Enum.map_join(products_orders, "\n", & "- #{&1["product_detail"].name} (x#{&1["quantity"]})")

    message = """
      *NEW ORDER RECEIVED!*
      Customer: #{if user_id, do: user_id, else: "Guest"}
      Table: #{transaction.table_number}
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
