defmodule StripeManaged.ProductTest do
  use ExUnit.Case, async: false

  alias StripeManaged.{Product, TestHelpers}

  setup do
    %{opts: TestHelpers.test_opts()}
  end

  test "create/2 returns product with ID", %{opts: opts} do
    params = %{
      name: "Pro Plan",
      tax_code: "txcd_10103001",
      default_price_data: %{unit_amount: 2900, currency: "usd", recurring: %{interval: "month"}}
    }

    assert {:ok, product} = Product.create(params, opts)
    assert product["id"] == "prod_test123"
    assert product["name"] == "Pro Plan"
    assert product["default_price"] == "price_test123"
  end

  test "retrieve/2 returns product by ID", %{opts: opts} do
    assert {:ok, product} = Product.retrieve("prod_abc", opts)
    assert product["id"] == "prod_abc"
    assert product["object"] == "product"
  end

  test "delete/2 returns deleted confirmation", %{opts: opts} do
    assert {:ok, result} = Product.delete("prod_abc", opts)
    assert result["deleted"] == true
  end

  test "list/2 returns product list", %{opts: opts} do
    assert {:ok, result} = Product.list(%{}, opts)
    assert result["object"] == "list"
    assert length(result["data"]) == 2
  end

  test "list_all/2 returns stream of products", %{opts: opts} do
    products = Product.list_all(%{}, opts) |> Enum.to_list()
    assert length(products) == 2
    assert hd(products)["id"] == "prod_1"
  end
end
