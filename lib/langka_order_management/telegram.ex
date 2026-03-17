defmodule LangkaOrderManagement.Telegram do
  alias LangkaOrderManagement.Employee

  def telegram_channel_id() do
    :langka_order_management
    |> Application.get_env(:telegram_integration)
    |> Keyword.get(:channel_id)
  end

  def telegram_token() do
    Application.get_env(:nadia, :token)
  end

  def send_order_payload_to_channel(customer_name, phone_number, transaction, products_orders) do
    employees = Employee.list_active_employees()

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

    message = build_order_message(customer_name, phone_number, transaction, items_list, nil)
    keyboard = build_order_inline_keyboard(transaction.id, employees, nil)

    Nadia.send_message(telegram_channel_id(), message, [
      parse_mode: "Markdown",
      reply_markup: %{inline_keyboard: keyboard}
    ])
  end

  def build_order_message(customer_name, phone_number, transaction, items_list, assigned_employee_name) do
    assigned_line =
      case assigned_employee_name do
        nil -> "Assigned: (tap your name below)"
        "" -> "Assigned: (tap your name below)"
        name -> "Assigned: #{name}"
      end

    discount_line =
      if transaction.discount_amount_as_usd && Decimal.gt?(transaction.discount_amount_as_usd, Decimal.new("0")) do
        "Discount: #{transaction.discount_as_percent_applied}% (-$#{transaction.discount_amount_as_usd})"
      else
        "Discount: none"
      end

    total_before = Map.get(transaction, :bill_price_before_discount_as_usd) || transaction.bill_price_as_usd
    total_after = Map.get(transaction, :bill_price_after_discount_as_usd) || transaction.bill_price_as_usd

    """
      *NEW ORDER RECEIVED!*
      Customer: #{customer_name} (#{phone_number})
      Table: #{transaction.seating_table_id}
      #{assigned_line}
      Items:
      #{items_list}
      Total before discount: $#{total_before}
      #{discount_line}
      Total after discount: $#{total_after}
    """
  end

  def build_order_inline_keyboard(transaction_id, employees, assigned_employee_id) do
    employee_buttons =
      employees
      |> Enum.map(fn employee ->
        text =
          if assigned_employee_id == employee.id do
            "[assigned] #{employee.name}"
          else
            employee.name
          end

        %{text: text, callback_data: "transaction:assign:#{transaction_id}:#{employee.id}"}
      end)
      |> Enum.chunk_every(2)

    action_buttons = [
      [
        %{text: "Complete", callback_data: "transaction:complete:#{transaction_id}"},
        %{text: "Cancel", callback_data: "transaction:cancel:#{transaction_id}"}
      ]
    ]

    employee_buttons ++ action_buttons
  end

  def update_assigned_employee_line(text, assigned_employee_name) when is_binary(text) do
    new_line =
      case assigned_employee_name do
        nil -> "Assigned: (tap your name below)"
        "" -> "Assigned: (tap your name below)"
        name -> "Assigned: #{name}"
      end

    if String.match?(text, ~r/^\s*Assigned:\s*.*$/m) do
      Regex.replace(~r/^\s*Assigned:\s*.*$/m, text, new_line)
    else
      String.trim_trailing(text) <> "\n" <> new_line
    end
  end
end
