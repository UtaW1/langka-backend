defmodule LangkaOrderManagement.ContextUtil do
  @moduledoc false

  import Ecto.Query, warn: false

  def list(query, filters) do
    limit = get_record_listing_limit(filters)

    sorting =
      if filters["sort"] == "asc" do
        [asc: :id]
      else
        [desc: :id]
      end

    cursor_paging =
      case {filters["sort"], filters["cursor_id"]} do
        {_, cursor_id} when cursor_id in [0, nil] ->
          dynamic(true)

        {"asc", cursor_id} ->
          dynamic([x], x.id > ^cursor_id)

        {_, cursor_id} ->
          dynamic([x], x.id < ^cursor_id)
      end

    filters
    |> Enum.reduce(query, fn
      {"label", name}, query ->
        where(query, [x], ilike(x.name, ^"%#{name}%"))

      {"ids.not_in", ids}, query ->
        where(query, [x], x.id not in ^ids)

      {ids_query, ids}, query when ids_query in ["ids", "ids.in"] ->
        where(query, [x], x.id in ^ids)

      {"page_number", page_number}, query ->
        offset(query, ^(page_number * limit))

      {"is_removed", is_removed}, query ->
        where(query, [x], not is_nil(x.removed_datetime) == ^(is_removed == "yes"))

      _, query -> query
    end)
    |> where(^cursor_paging)
    |> order_by(^sorting)
    |> limit(^limit)
  end

  defp get_record_listing_limit(%{"limit" => lim}), do: lim

  defp get_record_listing_limit(%{"page_size" => lim}), do: lim

  defp get_record_listing_limit(_), do: 16
end
