defmodule StripeManaged.ClientTest do
  use ExUnit.Case, async: false

  alias StripeManaged.{Client, TestHelpers}

  doctest StripeManaged.Client

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

  describe "request headers" do
    setup %{opts: opts} do
      %{echo_opts: Keyword.put(opts, :base_url, opts[:base_url] <> "/v1/echo")}
    end

    test "sends auth and version headers", %{echo_opts: opts} do
      assert {:ok, echo} = Client.get("/x", opts)
      assert echo["headers"]["authorization"] == "Bearer sk_test_fake"
      assert echo["headers"]["stripe-version"] == "2025-03-31.basil"
    end

    test "POST gets a generated idempotency key", %{echo_opts: opts} do
      assert {:ok, echo1} = Client.post("/x", %{a: 1}, opts)
      assert {:ok, echo2} = Client.post("/x", %{a: 1}, opts)

      key1 = echo1["headers"]["idempotency-key"]
      key2 = echo2["headers"]["idempotency-key"]

      assert key1 =~ ~r/^[0-9a-f]{32}$/
      assert key1 != key2
    end

    test "POST uses the idempotency key from opts", %{echo_opts: opts} do
      opts = Keyword.put(opts, :idempotency_key, "order-42")
      assert {:ok, echo} = Client.post("/x", %{}, opts)
      assert echo["headers"]["idempotency-key"] == "order-42"
    end

    test "GET and DELETE don't send an idempotency key", %{echo_opts: opts} do
      assert {:ok, get} = Client.get("/x", opts)
      assert {:ok, delete} = Client.delete("/x", opts)

      refute Map.has_key?(get["headers"], "idempotency-key")
      refute Map.has_key?(delete["headers"], "idempotency-key")
    end

    test "POST sends a form-encoded body", %{echo_opts: opts} do
      assert {:ok, echo} = Client.post("/x", %{line_items: [%{price: "p_1", quantity: 2}]}, opts)
      assert echo["headers"]["content-type"] =~ "application/x-www-form-urlencoded"

      assert echo["body_params"] == %{
               "line_items" => %{"0" => %{"price" => "p_1", "quantity" => "2"}}
             }
    end
  end

  describe "get_with_params/3" do
    test "encodes params as query string", %{opts: opts} do
      opts = Keyword.put(opts, :base_url, opts[:base_url] <> "/v1/echo")

      assert {:ok, echo} =
               Client.get_with_params(
                 "/v1/invoices",
                 %{limit: 3, expand: ["data.customer"]},
                 opts
               )

      assert URI.decode_query(echo["query_string"]) == %{
               "limit" => "3",
               "expand[0]" => "data.customer"
             }
    end

    test "empty params produce no query string", %{opts: opts} do
      opts = Keyword.put(opts, :base_url, opts[:base_url] <> "/v1/echo")
      assert {:ok, echo} = Client.get_with_params("/v1/invoices", %{}, opts)
      assert echo["query_string"] == ""
    end
  end

  describe "delete_with_params/3" do
    test "encodes params as query string", %{opts: opts} do
      opts = Keyword.put(opts, :base_url, opts[:base_url] <> "/v1/echo")
      assert {:ok, echo} = Client.delete_with_params("/x", %{prorate: true}, opts)
      assert echo["method"] == "DELETE"
      assert echo["query_string"] == "prorate=true"
    end
  end

  describe "path/2" do
    test "joins segments" do
      assert Client.path("/v1/subscriptions", ["sub_1", "resume"]) ==
               "/v1/subscriptions/sub_1/resume"
    end

    test "URL-encodes segments so IDs can't escape the resource path" do
      assert Client.path("/v1/customers", ["../charges"]) == "/v1/customers/..%2Fcharges"
      assert Client.path("/v1/customers", ["a?b=c#d"]) == "/v1/customers/a%3Fb%3Dc%23d"
    end

    test "raises for nil or empty IDs" do
      assert_raise ArgumentError, ~r/non-empty ID/, fn -> Client.path("/v1/customers", [nil]) end
      assert_raise ArgumentError, ~r/non-empty ID/, fn -> Client.path("/v1/customers", [""]) end
    end

    test "resource modules send encoded IDs", %{opts: opts} do
      opts = Keyword.put(opts, :base_url, opts[:base_url] <> "/v1/echo")
      assert {:ok, echo} = StripeManaged.Customer.retrieve("../charges", opts)
      assert echo["request_path"] == "/v1/echo/v1/customers/..%2Fcharges"
    end
  end

  test "flatten_params/1 drops nil values" do
    params = %{name: "Test", description: nil, metadata: %{a: nil, b: "1"}}
    flat = Client.flatten_params(params)

    assert Enum.sort(flat) == [{"metadata[b]", "1"}, {"name", "Test"}]
  end

  test "flatten_params/1 keeps empty strings (used to unset fields)" do
    assert Client.flatten_params(%{description: ""}) == [{"description", ""}]
  end

  test "flatten_params/1 handles false booleans" do
    assert Client.flatten_params(%{active: false}) == [{"active", "false"}]
  end

  test "flatten_params/1 handles lists of scalars" do
    flat = Client.flatten_params(%{expand: ["customer", "subscription"]})
    assert flat == [{"expand[0]", "customer"}, {"expand[1]", "subscription"}]
  end

  test "returns network error when the server is unreachable" do
    opts = [api_key: "sk_test_fake", base_url: "http://localhost:1", max_retries: 0]

    assert {:error, error} = Client.get("/v1/products", opts)
    assert error.type == :network
    assert error.message =~ "Network error"
  end

  describe "list_paginated/3 edge cases" do
    test "stops when has_more is true but data is empty", %{opts: opts} do
      assert Client.list_paginated("/v1/paginated_empty_has_more", %{}, opts) |> Enum.to_list() ==
               []
    end

    test "emits error and halts when a later page fails", %{opts: opts} do
      opts = Keyword.put(opts, :max_retries, 0)
      items = Client.list_paginated("/v1/paginated_error", %{}, opts) |> Enum.to_list()

      assert [%{"id" => "item_1"}, {:error, %StripeManaged.Error{status: 500}}] = items
    end

    test "emits error for an unexpected response shape", %{opts: opts} do
      assert [{:error, %StripeManaged.Error{type: :api_error}}] =
               Client.list_paginated("/v1/paginated_not_a_list", %{}, opts) |> Enum.to_list()
    end

    test "emits error for a failed first page", %{opts: opts} do
      assert [{:error, %StripeManaged.Error{status: 404}}] =
               Client.list_paginated("/v1/error/404", %{}, opts) |> Enum.to_list()
    end

    test "is lazy and fetches only needed pages", %{opts: opts} do
      assert Client.list_paginated("/v1/paginated", %{}, opts) |> Enum.take(1) == [
               %{"id" => "item_1"}
             ]
    end

    test "replaces user-supplied cursor params with starting_after", %{opts: opts} do
      items =
        Client.list_paginated("/v1/paginated", %{"ending_before" => "x"}, opts)
        |> Enum.map(& &1["id"])

      assert items == ["item_1", "item_2", "item_3", "item_4"]
    end
  end
end
