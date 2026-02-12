defmodule LangkaOrderManagement.Payment do
  alias LangkaOrderManagement.{
    Product,
    Promotion
  }

  def use_promotion_if_applicable(%Decimal{} = grand_total_price_as_usd, %Promotion.Promotion{discount_as_percent: percentage_discount = %Decimal{}}) do
    percent_to_discount_to_decimal = Decimal.div(percentage_discount, Decimal.new("100"))

    discounted_amount = Decimal.mult(grand_total_price_as_usd, percent_to_discount_to_decimal)

    price_after_discount = Decimal.sub(grand_total_price_as_usd, discounted_amount)

    {price_after_discount, discounted_amount}
  end

  def use_promotion_if_applicable(grand_total_price_as_usd, _), do: {grand_total_price_as_usd, nil}

  def calculate_final_price(products_orders, promotion_apply) do
    product_ids = Enum.map(products_orders, & &1["product_id"])

    product_with_prices = Product.get_product_with_latest_price(product_ids)

    products_by_id = Map.new(product_with_prices, fn product ->
      {product.id, product}
    end)

    products_orders =
      Enum.map(products_orders, fn product_order ->
        product_id = product_order["product_id"]
        quantity = product_order["quantity"]

        enriched_product = Map.get(products_by_id, product_id)

        product_price = enriched_product.latest_product_price

        total_price_as_usd =
          cond do
            is_nil(quantity) ->
              Decimal.new(0)

            quantity == 0 ->
              Decimal.new(0)

            true ->
              Decimal.mult(product_price, Decimal.new(quantity))
          end


        product_order
        |> Map.put("product_detail", enriched_product)
        |> Map.put("total_price_as_usd", total_price_as_usd)
      end)

    total_price_as_usd =
      Enum.reduce(products_orders, Decimal.new("0"), fn product_order, acc ->
        total_price_as_usd = product_order["total_price_as_usd"]

        Decimal.add(acc, total_price_as_usd)
      end)

    {grand_total_price_as_usd, discount_amount} = use_promotion_if_applicable(total_price_as_usd, promotion_apply)

    {grand_total_price_as_usd, products_orders, discount_amount}
  end
end
