defmodule LangkaOrderManagementWeb.TelegramWebhook do
  require Logger
  alias LangkaOrderManagement.Account

  def perform(conn, %{"callback_query" => %{"data" => "order:complete:" <> id, "message" => message}}) do
    with transaction when not is_nil(transaction) <- Account.get_transaction_by_id(id),
         transaction when not is_tuple(transaction) <- Account.complete_order_on_webhook_callback(transaction)
    do
      Nadia.edit_message_text(message["chat"]["id"], message["message_id"], "", "Order #{id} is completed!")

      Plug.Conn.send_resp(conn, 200, "")
    else
      {:error, :transaction_in_non_processable_state} ->
        Logger.info("Transaction #{id} is nil for some reason, sending 200 anyways")

        Plug.Conn.send_resp(conn, 200, "")
    end
  end

  def perform(conn, %{"callback_query" => %{"data" => "order:cancel:" <> id, "message" => message}}) do
    with transaction when not is_nil(transaction) <- Account.get_transaction_by_id(id),
         transaction when not is_tuple(transaction) <- Account.cancel_order_on_webhook_callback(transaction)
    do
      Nadia.edit_message_text(message["chat"]["id"], message["message_id"], "", "Order #{id} is cancelled!")

      Plug.Conn.send_resp(conn, 200, "")
    else
      {:error, :transaction_in_non_processable_state} ->
        Logger.info("Transaction is nil for some reason, sending 200 anyways")

        Plug.Conn.send_resp(conn, 200, "")
    end
  end

end
