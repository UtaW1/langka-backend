defmodule LangkaOrderManagementWeb.UpdateCompletedTransactionInvoice do
  alias LangkaOrderManagement.Account

  alias LangkaOrderManagementWeb.ControllerUtils

  def rules(_) do
    %{
      "id" => [required: true, nullable: false, type: :string],
      "invoice_id" => [required: true, nullable: false, type: :string]
    }
  end

  def perform(conn, %{"id" => id, "invoice_id" => invoice_id}) do
    with {:ok, transaction} <- Account.update_completed_transaction_invoice_id(id, invoice_id) do
      conn
      |> Phoenix.Controller.put_view(__MODULE__.View)
      |> Phoenix.Controller.render("update_completed_transaction_invoice.json", data: transaction)
    else
      {:error, :transaction_not_found_or_not_completed} ->
        ControllerUtils.render_error(conn, 404, "404.json", :transaction_not_found_or_not_completed, "")

      {:error, changeset} ->
        conn
        |> Plug.Conn.put_status(422)
        |> Phoenix.Controller.put_view(LangkaOrderManagementWeb.ErrorJSON)
        |> Phoenix.Controller.render("422.json", %{error: changeset})

      err ->
        ControllerUtils.render_error(conn, 500, "500.json", :unexpected_error, "#{inspect(err)}")
    end
  end

  defmodule View do
    def render("update_completed_transaction_invoice.json", %{data: transaction}) do
      %{
        id: transaction.id,
        invoice_id: transaction.invoice_id,
        status: transaction.status,
        updated_at: transaction.updated_at
      }
    end
  end
end
