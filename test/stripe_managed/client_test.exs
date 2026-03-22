defmodule StripeManaged.ClientTest do
  use ExUnit.Case, async: false

  alias StripeManaged.{Client, TestHelpers}

  setup do
    %{opts: TestHelpers.test_opts()}
  end

  test "get/2 makes authenticated GET request", %{opts: opts} do
    assert {:ok, body} = Client.get("/v1/products/prod_123", opts)
    assert body["id"] == "prod_123"
  end

  test "post/3 makes authenticated POST request", %{opts: opts} do
    assert {:ok, body} = Client.post("/v1/products", %{name: "Test"}, opts)
    assert body["id"] == "prod_test123"
  end

  test "delete/2 makes authenticated DELETE request", %{opts: opts} do
    assert {:ok, body} = Client.delete("/v1/products/prod_123", opts)
    assert body["deleted"] == true
  end

  test "returns error for 404", %{opts: opts} do
    assert {:error, error} = Client.get("/v1/error/404", opts)
    assert error.type == :invalid_request
    assert error.status == 404
    assert error.code == "resource_missing"
  end

  test "returns error for 401", %{opts: opts} do
    assert {:error, error} = Client.get("/v1/error/401", opts)
    assert error.type == :authentication
    assert error.status == 401
  end

  test "flatten_params/1 handles nested maps" do
    params = %{line_items: [%{price: "price_1", quantity: 1}]}
    flat = Client.flatten_params(params)

    assert {"line_items[0][price]", "price_1"} in flat
    assert {"line_items[0][quantity]", 1} in flat
  end

  test "flatten_params/1 handles deep nesting" do
    params = %{managed_payments: %{enabled: true}}
    flat = Client.flatten_params(params)

    assert {"managed_payments[enabled]", "true"} in flat
  end

  test "flatten_params/1 handles flat params" do
    params = %{name: "Test", amount: 2900}
    flat = Client.flatten_params(params)

    assert {"name", "Test"} in flat
    assert {"amount", 2900} in flat
  end

  test "flatten_params/1 handles atom values" do
    params = %{status: :active}
    flat = Client.flatten_params(params)
    assert {"status", "active"} in flat
  end

  test "flatten_params/1 handles list input" do
    input = [{"key", "value"}]
    assert Client.flatten_params(input) == input
  end

  test "list_paginated/3 fetches multiple pages", %{opts: opts} do
    items = Client.list_paginated("/v1/paginated", %{}, opts) |> Enum.to_list()
    assert length(items) == 4
    assert Enum.map(items, & &1["id"]) == ["item_1", "item_2", "item_3", "item_4"]
  end

  test "list_paginated/3 with default params", %{opts: opts} do
    items = Client.list_paginated("/v1/products", %{}, opts) |> Enum.to_list()
    assert length(items) == 2
  end
end
