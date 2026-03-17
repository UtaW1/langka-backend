defmodule LangkaOrderManagementWeb.TransactionStream do
  use LangkaOrderManagementWeb, :controller
  require Logger
  alias LangkaOrderManagement.Account

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
      |> put_resp_header("connection", "keep-alive")
      |> put_resp_header("x-accel-buffering", "no")
      |> stream_events(transaction_id)
    else
      conn
      |> put_status(400)
      |> json(%{"error" => "Invalid transaction_id"})
    end
  end

  def stream(conn, _params) do
    conn
    |> put_status(400)
    |> json(%{"error" => "transaction_id is required"})
  end

  defp subscribe_to_transaction(transaction_id) do
    Logger.info("Client subscribed to transaction: #{transaction_id}")
    Phoenix.PubSub.subscribe(LangkaOrderManagement.PubSub, "#{@topic}:#{transaction_id}")
  end

  defp stream_events(conn, transaction_id) do
    conn = send_chunked(conn, 200)

    with {:ok, conn} <- chunk(conn, "retry: 3000\n\n"),
         {:ok, conn} <- chunk(conn, ": connected to transaction stream\n\n"),
         {:ok, conn} <- maybe_send_initial_state(conn, transaction_id) do
      stream_loop(conn, transaction_id)
    else
      _ -> conn
    end
  end

  defp maybe_send_initial_state(conn, transaction_id) do
    case Account.get_transaction_by_id(transaction_id) do
      nil ->
        {:ok, conn}

      transaction ->
        {event_type, event_data} = initial_event_payload(transaction)

        case encode_event(event_type, event_data) do
          {:ok, encoded} -> chunk(conn, encoded)
          _ -> {:ok, conn}
        end
    end
  end

  defp initial_event_payload(%{status: "completed", employee_id: employee_id, employee: employee, id: id}) do
    employee_name = employee_name(employee)

    {
      :completed,
      %{
        status: "completed",
        message: completion_message(id, employee_name),
        employee_id: employee_id,
        employee_name: employee_name,
        transaction_id: id
      }
    }
  end

  defp initial_event_payload(%{status: "cancelled", employee_id: employee_id, employee: employee, id: id}) do
    employee_name = employee_name(employee)

    {
      :cancelled,
      %{
        status: "cancelled",
        message: cancel_message(id, employee_name),
        employee_id: employee_id,
        employee_name: employee_name,
        transaction_id: id
      }
    }
  end

  defp initial_event_payload(%{status: "pending", employee_id: employee_id, employee: employee, id: id}) when not is_nil(employee_id) do
    employee_name = employee_name(employee)

    {
      :assigned,
      %{
        status: "pending",
        message: "#{employee_name} is now preparing your order",
        employee_id: employee_id,
        employee_name: employee_name,
        transaction_id: id
      }
    }
  end

  defp initial_event_payload(%{status: "pending", id: id}) do
    {
      :queued,
      %{
        status: "pending",
        message: "Your order is in queue",
        transaction_id: id
      }
    }
  end

  defp initial_event_payload(%{status: status, id: id}) do
    {
      :status,
      %{
        status: status,
        message: "Order status is #{status}",
        transaction_id: id
      }
    }
  end

  defp employee_name(%{name: name}) when is_binary(name), do: name
  defp employee_name(_), do: nil

  defp completion_message(transaction_id, nil), do: "Order #{transaction_id} is completed!"
  defp completion_message(transaction_id, employee_name), do: "Order #{transaction_id} is completed by #{employee_name}!"

  defp cancel_message(transaction_id, nil), do: "Order #{transaction_id} is cancelled!"
  defp cancel_message(transaction_id, employee_name), do: "Order #{transaction_id} is cancelled by #{employee_name}!"

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
      event_name = event_name(event_type)

      payload = Jason.encode!(%{
        type: event_name,
        data: event_data,
        timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
      })

      {:ok, "event: #{event_name}\ndata: #{payload}\n\n"}
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

  defp event_name(event_type) when is_atom(event_type), do: Atom.to_string(event_type)
  defp event_name(event_type) when is_binary(event_type), do: event_type
  defp event_name(event_type), do: to_string(event_type)
end
