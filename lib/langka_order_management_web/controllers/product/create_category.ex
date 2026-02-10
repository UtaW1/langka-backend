defmodule LangkaOrderManagementWeb.CreateCategory do
  alias LangkaOrderManagement.Product

  def rules(_) do
    %{
      "name" => [required: true, nullable: false, type: :string, cast: :string],
      "description" => [required: false, nullable: true, type: :string, cast: :string]
    }
  end

  def perform(conn, args) do
    with {:ok, product_category} when not is_nil(product_category) <- Product.create_product_category(args) do
      conn
      |> Phoenix.Controller.put_view(__MODULE__.View)
      |> Phoenix.Controller.render("create_product_category.json", data: product_category)
    else
      {:error, changeset} ->
        conn
        |> Plug.Conn.put_status(500)
        |> Phoenix.Controller.put_view(LangkaOrderManagementWeb.ErrorJSON)
        |> Phoenix.Controller.render("500.json", %{error: :changeset_error, message: "changeset error #{inspect(changeset)}"})
    end
  end

  defmodule View do
    def render("create_product_category.json", %{data: category}) do
      %{
        id: category.id,
        name: category.name,
        description: category.description
      }
    end
  end
end
