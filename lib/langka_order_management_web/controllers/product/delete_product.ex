defmodule LangkaOrderManagementWeb.DeleteProduct do
  alias LangkaOrderManagement.Product

  alias LangkaOrderManagementWeb.ControllerUtils

  def rules(_) do
    %{
      "id" => [required: true, nullable: false, cast: :integer, type: :integer]
    }
  end

  def perform(conn, %{"id" => id}) do
    with product when not is_nil(product) <- Product.get_product(id),
         {:ok, _} <- Product.delete_product(product) do
          Plug.Conn.send_resp(conn, 204, "")
    else
      nil ->
        ControllerUtils.render_error(conn, 404, "404.json", "product not found", "")

      {:error, cs} ->
        conn
        |> Plug.Conn.put_status(422)
        |> Phoenix.Controller.put_view(EpicureCanteenWeb.ErrorJSON)
        |> Phoenix.Controller.render("422.json", %{error: cs})
    end
  end
end
