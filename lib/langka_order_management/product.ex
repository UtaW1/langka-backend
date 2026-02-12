defmodule LangkaOrderManagement.Product do
  import Ecto.Query, warn: false

  alias LangkaOrderManagement.{Repo, ContextUtil}

  alias LangkaOrderManagement.Product.{
    Product,
    ProductCategory,
    ProductPrice
  }

  # ─────────────────────────────
  # Product Categories
  # ─────────────────────────────

  def list_product_categories do
    Repo.all(ProductCategory)
  end

  def get_product_category!(id), do: Repo.get!(ProductCategory, id)

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
    Repo.delete(category)
  end

  def change_product_category(%ProductCategory{} = category, attrs \\ %{}) do
    ProductCategory.changeset(category, attrs)
  end

  # ─────────────────────────────
  # Products
  # ─────────────────────────────

  def list_products do
    Product
    |> preload([:product_category, :product_prices])
    |> Repo.all()
  end

  def get_product!(id) do
    Product
    |> preload([:product_category, :product_prices])
    |> Repo.get!(id)
  end

  def create_product(attrs \\ %{}) do
    %Product{}
    |> Product.changeset(attrs)
    |> Repo.insert()
  end

  def update_product(%Product{} = product, attrs) do
    product
    |> Product.changeset(attrs)
    |> Repo.update()
  end

  def delete_product(%Product{} = product) do
    Repo.delete(product)
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
    |> IO.inspect()
  end

  def list_product_categories_with_paging(filters) do
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

  defp filter_by_product_category(query, %{"product_category_ids" => pc_ids}),
    do: where(query, [_, product_category: pc], pc.id in ^pc_ids)

  defp filter_by_product_category(query, %{"product_category_id" => pc_id}),
    do: where(query, [_, product_category: pc], pc.id == ^pc_id)

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
        latest_price: lp
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
end
