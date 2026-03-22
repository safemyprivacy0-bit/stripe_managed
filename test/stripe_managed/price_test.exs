defmodule StripeManaged.PriceTest do
  use ExUnit.Case, async: false

  alias StripeManaged.{Price, TestHelpers}

  setup do
    %{opts: TestHelpers.test_opts()}
  end

  describe "create/2" do
    test "creates price with all params", %{opts: opts} do
      params = %{
        product: "prod_test123",
        unit_amount: 2900,
        currency: "usd",
        recurring: %{interval: "month"},
        tax_behavior: "exclusive"
      }

      assert {:ok, price} = Price.create(params, opts)
      assert price["id"] == "price_test123"
    end

    test "creates one-time price", %{opts: opts} do
      params = %{product: "prod_test123", unit_amount: 999, currency: "usd"}
      assert {:ok, price} = Price.create(params, opts)
      assert price["id"] == "price_test123"
    end
  end

  describe "retrieve/2" do
    test "returns price by ID", %{opts: opts} do
      assert {:ok, price} = Price.retrieve("price_abc", opts)
      assert price["id"] == "price_abc"
      assert price["unit_amount"] == 2900
      assert price["currency"] == "usd"
    end
  end

  describe "update/3" do
    test "updates price", %{opts: opts} do
      assert {:ok, price} = Price.update("price_abc", %{active: false}, opts)
      assert price["id"] == "price_abc"
      assert price["object"] == "price"
    end
  end

  describe "list/2" do
    test "returns price list", %{opts: opts} do
      assert {:ok, result} = Price.list(%{}, opts)
      assert result["object"] == "list"
      assert length(result["data"]) == 1
    end

    test "filters by product", %{opts: opts} do
      assert {:ok, result} = Price.list(%{product: "prod_test123"}, opts)
      assert result["object"] == "list"
    end
  end

  describe "list_all/2" do
    test "returns stream of prices", %{opts: opts} do
      prices = Price.list_all(%{}, opts) |> Enum.to_list()
      assert length(prices) == 1
    end
  end
end
