defmodule LangkaOrderManagementWeb.ListUser do
  alias LangkaOrderManagement.Account

  def rules(_) do
    %{
      "page_size" => [required: true, cast: :integer, type: :integer, between: {2, 16}],
      "page_number" => [required: false, nullable: true, cast: :integer, type: :integer, min: 0],
      "cursor_id" => [required: false, nullable: true, cast: :integer, type: :integer, min: 0]
    }
  end

  def perform(conn, filters) do
    {users, count} = Account.list_all_users(filters)

    conn
    |> Plug.Conn.put_resp_header("x-paging-total-count", "#{count}")
    |> Phoenix.Controller.put_view(__MODULE__.View)
    |> Phoenix.Controller.render("list_users.json", data: users)
  end

  defmodule View do
    def render("list_users.json", %{data: users}) do
      Enum.map(users, & %{
        id: &1.id,
        username: &1.username,
        phone_number: &1.phone_number
      })
    end
  end
end
