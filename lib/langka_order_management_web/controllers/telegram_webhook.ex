defmodule LangkaOrderManagementWeb.TelegramWebhook do
  require Logger
  alias LangkaOrderManagement.Account
  alias LangkaOrderManagement.{Employee, Telegram}

  def rules(_) do
    %{
      "callback_query" => [required: false, nullable: true, type: :map]
    }
  end

  def perform(conn, %{"callback_query" => %{"id" => callback_id, "data" => "transaction:assign:" <> rest, "message" => message}}) do
    case String.split(rest, ":", parts: 2) do
      [transaction_id, employee_id_str] ->
        with {employee_id, ""} <- Integer.parse(employee_id_str),
             transaction when not is_nil(transaction) <- Account.get_transaction_by_id(transaction_id),
             employee when not is_nil(employee) <- Employee.get_employee(employee_id),
             {:ok, _updated_transaction} <- Account.assign_employee_to_transaction(transaction, employee_id)
        do
          employees = Employee.list_active_employees()
          updated_text = Telegram.update_assigned_employee_line(message["text"] || "", employee.name)
          keyboard = Telegram.build_order_inline_keyboard(transaction_id, employees, employee_id)

          Nadia.edit_message_text(message["chat"]["id"], message["message_id"], "", updated_text,
            parse_mode: "Markdown",
            reply_markup: %{inline_keyboard: keyboard}
          )

          Nadia.answer_callback_query(callback_id, text: "Assigned to #{employee.name}")
          Plug.Conn.send_resp(conn, 200, "")
        else
          :error ->
            Nadia.answer_callback_query(callback_id, text: "Invalid employee")
            Plug.Conn.send_resp(conn, 200, "")

          nil ->
            Nadia.answer_callback_query(callback_id, text: "Not found")
            Plug.Conn.send_resp(conn, 200, "")

          {:error, :transaction_already_assigned} ->
            Nadia.answer_callback_query(callback_id, text: "Order already assigned")
            Plug.Conn.send_resp(conn, 200, "")

          {:error, _reason} ->
            Nadia.answer_callback_query(callback_id, text: "Could not assign")
            Plug.Conn.send_resp(conn, 200, "")
        end

      _ ->
        Nadia.answer_callback_query(callback_id, text: "Invalid assignment")
        Plug.Conn.send_resp(conn, 200, "")
    end
  end

  def perform(conn, %{"callback_query" => %{"id" => callback_id, "data" => "transaction:complete:" <> id, "message" => message}}) do
    with transaction when not is_nil(transaction) <- Account.get_transaction_by_id(id),
         :ok <- ensure_employee_assigned_or_no_employees(transaction, callback_id),
         {:ok, updated_transaction} <- Account.complete_order_on_webhook_callback(transaction)
    do
      employee_name = updated_transaction.employee && updated_transaction.employee.name
      completion_msg = if employee_name, do: "Order #{id} is completed by #{employee_name}!", else: "Order #{id} is completed!"

      Nadia.edit_message_text(message["chat"]["id"], message["message_id"], "", completion_msg)
      Plug.Conn.send_resp(conn, 200, "")
    else
      {:error, :employee_not_assigned} ->
        Plug.Conn.send_resp(conn, 200, "")

      {:error, :transaction_in_non_processable_state} ->
        Logger.info("Transaction #{id} is in non-processable state, acknowledging")
        Plug.Conn.send_resp(conn, 200, "")

      nil ->
        Logger.info("Transaction #{id} not found, acknowledging")
        Plug.Conn.send_resp(conn, 200, "")
    end
  end

  def perform(conn, %{"callback_query" => %{"id" => callback_id, "data" => "transaction:cancel:" <> id, "message" => message}}) do
    with transaction when not is_nil(transaction) <- Account.get_transaction_by_id(id),
         :ok <- ensure_employee_assigned_or_no_employees(transaction, callback_id),
         {:ok, updated_transaction} <- Account.cancel_order_on_webhook_callback(transaction)
    do
      employee_name = updated_transaction.employee && updated_transaction.employee.name
      cancel_msg = if employee_name, do: "Order #{id} is cancelled by #{employee_name}!", else: "Order #{id} is cancelled!"

      Nadia.edit_message_text(message["chat"]["id"], message["message_id"], "", cancel_msg)
      Plug.Conn.send_resp(conn, 200, "")
    else
      {:error, :employee_not_assigned} ->
        Plug.Conn.send_resp(conn, 200, "")

      {:error, :transaction_in_non_processable_state} ->
        Logger.info("Transaction #{id} is in non-processable state, acknowledging")
        Plug.Conn.send_resp(conn, 200, "")

      nil ->
        Logger.info("Transaction #{id} not found, acknowledging")
        Plug.Conn.send_resp(conn, 200, "")
    end
  end

  def perform(conn, body) do
    IO.inspect(body, label: "We are here")

    Plug.Conn.send_resp(conn, 200, "")
  end

  defp ensure_employee_assigned_or_no_employees(%{employee_id: employee_id}, callback_id) do
    employees = Employee.list_active_employees()

    cond do
      employees == [] ->
        :ok

      not is_nil(employee_id) ->
        :ok

      true ->
        Nadia.answer_callback_query(callback_id, text: "Select your name first")
        {:error, :employee_not_assigned}
    end
  end
end
