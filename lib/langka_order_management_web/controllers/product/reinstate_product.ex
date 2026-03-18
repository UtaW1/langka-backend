defmodule LangkaOrderManagementWeb.ReinstateProduct do
  alias LangkaOrderManagement.Product

  alias LangkaOrderManagementWeb.ControllerUtils

  def rules(_) do
    %{
      "id" => [required: true, nullable: false, cast: :integer, type: :integer]
    }
  end

  def perform(conn, %{"id" => id}) do
    with product when not is_nil(product) <- Product.get_product(id),
         false <- Product.category_removed?(product),
         {:ok, _} <- Product.reinstate_product(product) do
      Plug.Conn.send_resp(conn, 204, "")
    else
      nil ->
        ControllerUtils.render_error(conn, 404, "404.json", "product not found", "")

      true ->
        ControllerUtils.render_error(conn, 422, "422.json", :product_category_removed, "you have to reinstate the category first")

      {:error, cs} ->
        conn
        |> Plug.Conn.put_status(422)
        |> Phoenix.Controller.put_view(LangkaOrderManagementWeb.ErrorJSON)
        |> Phoenix.Controller.render("422.json", %{error: cs})
    end
  end
end
