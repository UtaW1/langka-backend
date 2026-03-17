defmodule LangkaOrderManagementWeb.DeleteCategory do
  alias LangkaOrderManagement.Product

  alias LangkaOrderManagementWeb.ControllerUtils

  def rules(_) do
    %{
      "id" => [required: true, nullable: false, cast: :integer, type: :integer]
    }
  end

  def perform(conn, %{"id" => id}) do
    with category when not is_nil(category) <- Product.get_product_category(id),
         {:ok, _} <- Product.delete_product_category(category) do

        Plug.Conn.send_resp(conn, 204, "")

    else
      nil ->
        ControllerUtils.render_error(conn, 404, "404.json", "seating table not found", "")

      {:error, changeset} ->
        conn
        |> Plug.Conn.put_status(422)
        |> Phoenix.Controller.put_view(LangkaOrderManagementWeb.ErrorJSON)
        |> Phoenix.Controller.render("422.json", %{error: changeset})
    end
  end
end
