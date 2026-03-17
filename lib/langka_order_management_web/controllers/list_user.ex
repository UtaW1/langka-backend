defmodule LangkaOrderManagementWeb.ListUser do
  alias LangkaOrderManagement.Account
  alias LangkaOrderManagementWeb.ControllerUtils

  def rules(_) do
    %{
      "page_size" => [required: true, cast: :integer, type: :integer, between: {2, 16}],
      "page_number" => [required: false, nullable: true, cast: :integer, type: :integer, min: 0],
      "cursor_id" => [required: false, nullable: true, cast: :integer, type: :integer, min: 0],
      "start_datetime" => [required: false, nullable: true, custom: &ControllerUtils.validate_iso8601_datetime/1],
      "end_datetime" => [required: false, nullable: true, custom: &ControllerUtils.validate_iso8601_datetime/1]
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
        phone_number: &1.phone_number,
        inserted_at: &1.inserted_at,
        total_completed_transactions: &1.total_completed_transactions,
        total_revenue_generated: &1.total_revenue_generated
      })
      |> Enum.sort_by(& &1.inserted_at, {:desc, NaiveDateTime})
    end
  end
end
