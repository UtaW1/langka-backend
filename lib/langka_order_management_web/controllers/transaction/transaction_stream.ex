defmodule LangkaOrderManagementWeb.TransactionStream do
  use LangkaOrderManagementWeb, :controller
  require Logger

  @topic "transaction_updates"

  @doc """
  Stream transaction updates via Server-Sent Events.

  Frontend connects with transaction_id as query param:
  GET /api/transaction/stream?transaction_id=<id>

  Subscribes to transaction updates and streams progress/status changes.
  """
  def stream(conn, %{"transaction_id" => transaction_id}) do
    if valid_transaction_id?(transaction_id) do
      subscribe_to_transaction(transaction_id)

      conn
      |> put_resp_header("content-type", "text/event-stream")
      |> put_resp_header("cache-control", "no-cache")
      |> put_resp_header("x-accel-buffering", "no")
      |> stream_events(transaction_id)
    else
      conn
      |> put_status(400)
      |> json(%{"error" => "Invalid transaction_id"})
    end
  end

  defp subscribe_to_transaction(transaction_id) do
    Logger.info("Client subscribed to transaction: #{transaction_id}")
    Phoenix.PubSub.subscribe(LangkaOrderManagement.PubSub, "#{@topic}:#{transaction_id}")
  end

  defp stream_events(conn, transaction_id) do
    conn = send_chunked(conn, 200)
    stream_loop(conn, transaction_id)
  end

  defp stream_loop(conn, transaction_id) do
    receive do
      {:transaction_event, event_type, event_data} ->
        case encode_event(event_type, event_data) do
          {:ok, encoded} ->
            case chunk(conn, encoded) do
              {:ok, conn} ->
                stream_loop(conn, transaction_id)

              {:error, :closed} ->
                Logger.info("SSE connection closed for transaction: #{transaction_id}")
                conn

              error ->
                Logger.error("Error sending SSE chunk: #{inspect(error)}")
                conn
            end

          error ->
            Logger.error("Error encoding event: #{inspect(error)}")
            stream_loop(conn, transaction_id)
        end

      _ ->
        stream_loop(conn, transaction_id)
    after
      30_000 ->
        case chunk(conn, ": heartbeat\n\n") do
          {:ok, conn} -> stream_loop(conn, transaction_id)
          {:error, :closed} -> conn
          _error -> conn
        end
    end
  end

  defp encode_event(event_type, event_data) do
    try do
      payload = Jason.encode!(%{
        type: Atom.to_string(event_type),
        data: event_data,
        timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
      })

      {:ok, "event: #{event_type}\ndata: #{payload}\n\n"}
    rescue
      e ->
        {:error, e}
    end
  end

  defp valid_transaction_id?(transaction_id) do
    # Validate transaction_id format (assuming UUID or numeric)
    String.match?(transaction_id, ~r/^[a-zA-Z0-9_-]+$/)
  end

  @doc """
  Publish transaction event to subscribed clients.

  Called from other parts of the app when transaction status changes.

  Example:
    LangkaOrderManagementWeb.TransactionStream.publish_event(
      transaction_id,
      :completed,
      %{"items_count" => 5, "total_price" => 150000}
    )
  """
  def publish_event(transaction_id, event_type, event_data \\ %{}) do
    Logger.info("Publishing transaction event: #{event_type} for transaction #{transaction_id}")
    Phoenix.PubSub.broadcast(
      LangkaOrderManagement.PubSub,
      "transaction_updates:#{transaction_id}",
      {:transaction_event, event_type, event_data}
    )
  end
end
