defmodule LangkaOrderManagement.Product do
  import Ecto.Query, warn: false

  alias LangkaOrderManagement.{Repo, ContextUtil, Supabase}

  alias LangkaOrderManagement.Product.{
    Product,
    ProductCategory,
    ProductPrice,
    ProductTransaction
  }

  @bucketname "product-images"

  # ─────────────────────────────
  # Product Categories
  # ─────────────────────────────

  def list_product_categories do
    Repo.all(ProductCategory)
  end

  def get_product_category(id), do: Repo.get(ProductCategory, id)

  def create_product_category(attrs \\ %{}) do
    %ProductCategory{}
    |> ProductCategory.changeset(attrs)
    |> Repo.insert()
  end

  def update_product_category(%ProductCategory{} = category, attrs) do
    category
    |> ProductCategory.changeset(attrs)
    |> Repo.update()
  end

  def delete_product_category(%ProductCategory{} = category) do
    Repo.transaction(fn ->
      from(p in Product, where: p.product_category_id == ^category.id)
      |> Repo.update_all(set: [removed_datetime: DateTime.truncate(DateTime.utc_now(), :second)])

      category
      |> ProductCategory.remove_changeset(%{removed_datetime: DateTime.truncate(DateTime.utc_now(), :second), removed_reason: "admin removed"})
      |> Repo.update()
    end)
  end

  def reinstate_product_category(%ProductCategory{} = category) do
    category
    |> Ecto.Changeset.change(%{removed_datetime: nil, removed_reason: nil})
    |> Repo.update()
  end

  def change_product_category(%ProductCategory{} = category, attrs \\ %{}) do
    ProductCategory.changeset(category, attrs)
  end

  # ─────────────────────────────
  # Products
  # ─────────────────────────────

  def list_products do
    Product
    |> preload([:product_category, :prices])
    |> Repo.all()
  end

  def get_product(id) do
    Product
    |> preload([:product_category, :prices])
    |> Repo.get(id)
  end

  def delete_product_image(%Product{image_url: "" <> url}) do
    encoded_url = URI.encode(url)

    case Supabase.remove(@bucketname, encoded_url) do
      {:ok, nil} ->
        {:ok, nil}

      err ->
        err
    end
  end

  def delete_product_image(_), do: {:ok, nil}

  def create_product(attrs \\ %{}) do
    %Product{}
    |> Product.changeset(attrs)
    |> Repo.insert()
  end

  def update_product(%Product{} = product, %{"price_as_usd" => price} = attrs) when is_float(price) do
    {:ok, product_price} = create_product_price(%{product_id: product.id, price_as_usd: price})

    {:ok, updated_product} =
      product
      |> Product.changeset(attrs)
      |> Repo.update()

    {:ok, %{updated_product | latest_product_price: product_price}}
  end

  def update_product(%Product{} = product, attrs) do
    {:ok, updated_product} =
      product
      |> Product.changeset(attrs)
      |> Repo.update()

    %{product: product, latest_product_price: latest_price} = get_product_with_latest_price(updated_product.id)

    {:ok, %{product | latest_product_price: latest_price}}
  end

  def delete_product(%Product{} = product) do
    product
    |> Product.changeset(%{removed_datetime: DateTime.truncate(DateTime.utc_now(), :second)})
    |> Repo.update()
  end

  def reinstate_product(%Product{} = product) do
    product
    |> Product.changeset(%{removed_datetime: nil})
    |> Repo.update()
  end

  def category_removed?(%Product{product_category: %ProductCategory{removed_datetime: removed_datetime}}),
    do: not is_nil(removed_datetime)

  def get_enriched_product_by_id(id) do
    product = get_product(id)

    if product do
      %{product: product, latest_product_price: latest_price} = get_product_with_latest_price(product.id)

      %{product | latest_product_price: latest_price}
    else
      nil
    end
  end

  def change_product(%Product{} = product, attrs \\ %{}) do
    Product.changeset(product, attrs)
  end

  # Optional soft-delete helper
  def soft_delete_product(%Product{} = product) do
    update_product(product, %{removed_datetime: DateTime.utc_now()})
  end

  # ─────────────────────────────
  # Product Prices
  # ─────────────────────────────
  def list_products_with_paging(filters) do
    filters = Map.put(filters, "is_load_latest_price", true)

    product_query =
      Product
      |> from(as: :product)
      |> join(:left, [p], _ in assoc(p, :product_category), as: :product_category)
      |> ContextUtil.list(filters)
      |> filter_by_product_category(filters)

    {
      product_query
      |> preload([_, product_category: pc], product_category: pc)
      |> load_latest_price(filters)
      |> distinct([p], [p.id])
      |> exclude(:order_by)
      |> order_by([p], [asc_nulls_last: :id])
      |> Repo.all(),

      product_query
      |> load_latest_price(filters)
      |> exclude(:limit)
      |> exclude(:offset)
      |> exclude(:order_by)
      |> exclude(:select)
      |> exclude(:preload)
      |> select([p], count(fragment("DISTINCT ?", p.id)))
      |> Repo.one()
    }
  end

  def list_product_categories_with_paging(filters) do
    filters = Map.put(filters, "is_removed", "no")

    product_category_query =
      ProductCategory
      |> from(as: :pc)
      |> join(:left, [pc], _ in assoc(pc, :products), as: :product)
      |> ContextUtil.list(filters)

    {
      product_category_query
      |> preload([_, p], products: ^products_with_latest_price_query())
      |> distinct([pc], pc.id)
      |> exclude(:order_by)
      |> order_by([p], [asc_nulls_last: :id])
      |> Repo.all(),

      product_category_query
      |> exclude(:limit)
      |> exclude(:offset)
      |> exclude(:order_by)
      |> exclude(:select)
      |> exclude(:preload)
      |> select([pc], count(fragment("DISTINCT ?", pc.id)))
      |> Repo.one()
    }
  end

  def list_monthly_product_quantity_metrics(filters \\ %{}) do
    {start_datetime, end_datetime} = resolve_metric_datetime_range(filters)

    ProductTransaction
    |> join(:inner, [pt], t in assoc(pt, :transaction))
    |> join(:inner, [pt, _t], p in assoc(pt, :product))
    |> where([_pt, t], t.status == ^"completed")
    |> where([_pt, t], t.inserted_at >= ^start_datetime and t.inserted_at <= ^end_datetime)
    |> group_by([_pt, _t, p], [p.id, p.name])
    |> select([pt, _t, p], %{
      product_id: p.id,
      product_name: p.name,
      total_quantity: sum(pt.quantity)
    })
    |> order_by([pt, _t, p], [desc: sum(pt.quantity), asc: p.name])
    |> Repo.all()
  end

  defp resolve_metric_datetime_range(filters) do
    start_datetime =
      case Map.get(filters, "start_datetime") do
        %DateTime{} = dt -> dt
        _ ->
          Date.utc_today()
          |> Date.beginning_of_month()
          |> DateTime.new!(~T[00:00:00], "Etc/UTC")
      end

    end_datetime =
      case Map.get(filters, "end_datetime") do
        %DateTime{} = dt -> dt
        _ ->
          Date.utc_today()
          |> Date.end_of_month()
          |> DateTime.new!(~T[23:59:59], "Etc/UTC")
      end

    {start_datetime, end_datetime}
  end

  defp products_with_latest_price_query do
    Product
    |> from(as: :product)
    |> join(:left_lateral, [], pp in subquery(
      from pp in ProductPrice,
        where: pp.product_id == parent_as(:product).id,
        order_by: [desc: pp.id],
        limit: 1
    ), on: true)
    |> select_merge([_, pp], %{
      latest_product_price: pp
    })
  end

  defp filter_by_product_category(query, %{"product_category_ids" => pc_ids}) when is_list(pc_ids),
    do: where(query, [_, product_category: pc], pc.id in ^pc_ids)

  defp filter_by_product_category(query, %{"product_category_id" => pc_id}) when not is_nil(pc_id),
    do: where(query, [_, product_category: pc], pc.id == ^pc_id)

  defp filter_by_product_category(query, %{"category_id" => category_id}) when not is_nil(category_id),
    do: where(query, [_, product_category: pc], pc.id == ^category_id)

  defp filter_by_product_category(query, %{"product_category_ids" => nil}), do: query

  defp filter_by_product_category(query, %{"product_category_id" => nil}), do: query

  defp filter_by_product_category(query, %{"category_id" => nil}), do: query

  defp filter_by_product_category(query, _), do: query

  defp load_latest_price(query, %{"is_load_latest_price" => true}) do
    query
    |> query_with_latest_product_price(:product)
    |> select([p, product_price: pp], %{product: p, latest_product_price: pp})
  end

  defp load_latest_price(query, _) do
    query
    |> join(:left, [p], _ in assoc(p, :prices), as: :product_price)
    |> preload([product_price: pp], prices: pp)
  end

  defp query_with_latest_product_price(query, parent_query_key) do
    join(
      query,
      :left_lateral,
      [],
      subquery(
        ProductPrice
        |> where([pp], pp.product_id == parent_as(^parent_query_key).id)
        |> order_by(desc: :id)
        |> limit(1)
      ),
      on: true,
      as: :product_price
    )
  end

  def get_product_with_latest_price([_ | _] = product_ids) do
    last_price_subquery =
      ProductPrice
      |> where([pp], pp.product_id == parent_as(:p).id)
      |> order_by(desc: :inserted_at)
      |> select([pp], %{price_as_usd: pp.price_as_usd})
      |> limit(1)

    Product
    |> from(as: :p)
    |> join(:left_lateral, [], subquery(last_price_subquery), on: true, as: :pp)
    |> where([p], p.id in ^product_ids)
    |> preload([p], :product_category)
    |> select([p, pp], %{
      p |
      latest_product_price: pp.price_as_usd
    })
    |> Repo.all()
  end

  def get_product_with_latest_price(product_id) do
    latest_price_query =
      from pp in ProductPrice,
        where: pp.product_id == ^product_id,
        order_by: [desc: pp.inserted_at],
        limit: 1

    from(p in Product,
      where: p.id == ^product_id,
      left_join: lp in subquery(latest_price_query),
        on: lp.product_id == p.id,
      preload: [:product_category],
      select: %{
        product: p,
        latest_product_price: lp
      }
    )
    |> Repo.one()
  end

  def list_product_prices do
    Repo.all(ProductPrice)
  end

  def list_product_prices_for_product(product_id) do
    from(pp in ProductPrice, where: pp.product_id == ^product_id)
    |> Repo.all()
  end

  def get_product_price!(id), do: Repo.get!(ProductPrice, id)

  def create_product_price(attrs \\ %{}) do
    %ProductPrice{}
    |> ProductPrice.changeset(attrs)
    |> Repo.insert()
  end

  def update_product_price(%ProductPrice{} = product_price, attrs) do
    product_price
    |> ProductPrice.changeset(attrs)
    |> Repo.update()
  end

  def delete_product_price(%ProductPrice{} = product_price) do
    Repo.delete(product_price)
  end

  def change_product_price(%ProductPrice{} = product_price, attrs \\ %{}) do
    ProductPrice.changeset(product_price, attrs)
  end

  def upload_product_image(%Plug.Upload{path: tmp_path, content_type: content_type}, %Product{name: name, id: id} = product) do
    timestamp =
      DateTime.utc_now()
      |> DateTime.to_iso8601()
      |> String.slice(0..18)
      |> String.replace(~r/[^0-9]/, "")

    normalized_name = String.replace(name, " ", "-")

    filename = "product-#{id}-#{normalized_name}:#{Nanoid.generate(32)}:#{timestamp}"

    content_type =
      content_type
      |> String.split("/")
      |> List.last()

    file_path = "product/#{filename}.#{content_type}"

    encoded_file_path = URI.encode(file_path)

    tmp_path = File.read!(tmp_path)

    case Supabase.upload(@bucketname, tmp_path, encoded_file_path) do
      {:ok, _} ->
        product
        |> Product.changeset(%{image_url: file_path})
        |> Repo.update()

      {:error, reason} ->
        {:error, %{upload_error: reason}}
    end
  end
end
