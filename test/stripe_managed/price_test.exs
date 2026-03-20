defmodule StripeManaged.PriceTest do
  use ExUnit.Case, async: false

  alias StripeManaged.{Price, TestHelpers}

  setup do
    %{opts: TestHelpers.test_opts()}
  end

  test "create/2 returns price", %{opts: opts} do
    params = %{product: "prod_test123", unit_amount: 2900, currency: "usd"}
    assert {:ok, price} = Price.create(params, opts)
    assert price["id"] == "price_test123"
  end

  test "retrieve/2 returns price by ID", %{opts: opts} do
    assert {:ok, price} = Price.retrieve("price_abc", opts)
    assert price["id"] == "price_abc"
    assert price["unit_amount"] == 2900
  end

  test "list/2 returns price list", %{opts: opts} do
    assert {:ok, result} = Price.list(%{}, opts)
    assert result["object"] == "list"
    assert length(result["data"]) == 1
  end
end
