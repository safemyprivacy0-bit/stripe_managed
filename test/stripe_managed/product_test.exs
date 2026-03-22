defmodule StripeManaged.ProductTest do
  use ExUnit.Case, async: false

  alias StripeManaged.{Product, TestHelpers}

  setup do
    %{opts: TestHelpers.test_opts()}
  end

  describe "create/2" do
    test "creates product with all params", %{opts: opts} do
      params = %{
        name: "Pro Plan",
        description: "Full access",
        tax_code: "txcd_10103001",
        default_price_data: %{unit_amount: 2900, currency: "usd", recurring: %{interval: "month"}}
      }

      assert {:ok, product} = Product.create(params, opts)
      assert product["id"] == "prod_test123"
      assert product["name"] == "Pro Plan"
      assert product["default_price"] == "price_test123"
      assert product["active"] == true
    end

    test "creates product with minimal params", %{opts: opts} do
      assert {:ok, product} = Product.create(%{name: "Basic"}, opts)
      assert product["id"] == "prod_test123"
    end
  end

  describe "retrieve/2" do
    test "returns product by ID", %{opts: opts} do
      assert {:ok, product} = Product.retrieve("prod_abc", opts)
      assert product["id"] == "prod_abc"
      assert product["object"] == "product"
    end
  end

  describe "update/3" do
    test "updates product fields", %{opts: opts} do
      assert {:ok, product} = Product.update("prod_abc", %{name: "Updated"}, opts)
      assert product["id"] == "prod_abc"
      assert product["object"] == "product"
    end
  end

  describe "delete/2" do
    test "deletes product", %{opts: opts} do
      assert {:ok, result} = Product.delete("prod_abc", opts)
      assert result["deleted"] == true
    end
  end

  describe "list/2" do
    test "returns product list", %{opts: opts} do
      assert {:ok, result} = Product.list(%{}, opts)
      assert result["object"] == "list"
      assert length(result["data"]) == 2
    end

    test "accepts filter params", %{opts: opts} do
      assert {:ok, result} = Product.list(%{active: true, limit: 10}, opts)
      assert result["object"] == "list"
    end
  end

  describe "list_all/2" do
    test "returns stream of products", %{opts: opts} do
      products = Product.list_all(%{}, opts) |> Enum.to_list()
      assert length(products) == 2
      assert hd(products)["id"] == "prod_1"
    end

    test "accepts filter params", %{opts: opts} do
      products = Product.list_all(%{active: true}, opts) |> Enum.to_list()
      assert is_list(products)
    end
  end
end
