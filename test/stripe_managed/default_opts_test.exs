defmodule StripeManaged.DefaultOptsTest do
  @moduledoc """
  Tests that verify all resource functions work with config from Application env
  (no explicit opts), covering the default argument branches.
  """
  use ExUnit.Case, async: false

  alias StripeManaged.TestHelpers

  setup do
    opts = TestHelpers.test_opts()
    Application.put_env(:stripe_managed, :api_key, opts[:api_key])
    Application.put_env(:stripe_managed, :base_url, opts[:base_url])
    Application.put_env(:stripe_managed, :api_version, opts[:api_version])

    on_exit(fn ->
      Application.delete_env(:stripe_managed, :api_key)
      Application.delete_env(:stripe_managed, :base_url)
      Application.delete_env(:stripe_managed, :api_version)
    end)
  end

  # Product

  test "Product.create/1 with default opts" do
    assert {:ok, _} = StripeManaged.Product.create(%{name: "Test"})
  end

  test "Product.retrieve/1 with default opts" do
    assert {:ok, _} = StripeManaged.Product.retrieve("prod_1")
  end

  test "Product.update/2 with default opts" do
    assert {:ok, _} = StripeManaged.Product.update("prod_1", %{name: "X"})
  end

  test "Product.delete/1 with default opts" do
    assert {:ok, _} = StripeManaged.Product.delete("prod_1")
  end

  test "Product.list/0 with default opts" do
    assert {:ok, _} = StripeManaged.Product.list()
  end

  test "Product.list_all/0 with default opts" do
    result = StripeManaged.Product.list_all() |> Enum.to_list()
    assert is_list(result)
  end

  # Price

  test "Price.create/1 with default opts" do
    assert {:ok, _} = StripeManaged.Price.create(%{product: "prod_1", unit_amount: 100, currency: "usd"})
  end

  test "Price.retrieve/1 with default opts" do
    assert {:ok, _} = StripeManaged.Price.retrieve("price_1")
  end

  test "Price.update/2 with default opts" do
    assert {:ok, _} = StripeManaged.Price.update("price_1", %{active: false})
  end

  test "Price.list/0 with default opts" do
    assert {:ok, _} = StripeManaged.Price.list()
  end

  test "Price.list_all/0 with default opts" do
    result = StripeManaged.Price.list_all() |> Enum.to_list()
    assert is_list(result)
  end

  # Checkout Session

  test "CheckoutSession.create/1 with default opts" do
    params = %{
      line_items: [%{price: "price_1", quantity: 1}],
      mode: "subscription",
      managed_payments: %{enabled: true},
      success_url: "https://example.com/ok"
    }

    assert {:ok, _} = StripeManaged.CheckoutSession.create(params)
  end

  test "CheckoutSession.retrieve/1 with default opts" do
    assert {:ok, _} = StripeManaged.CheckoutSession.retrieve("cs_1")
  end

  test "CheckoutSession.list/0 with default opts" do
    assert {:ok, _} = StripeManaged.CheckoutSession.list()
  end

  test "CheckoutSession.expire/1 with default opts" do
    assert {:ok, _} = StripeManaged.CheckoutSession.expire("cs_1")
  end

  test "CheckoutSession.list_line_items/1 with default opts" do
    assert {:ok, _} = StripeManaged.CheckoutSession.list_line_items("cs_1")
  end

  # Subscription

  test "Subscription.retrieve/1 with default opts" do
    assert {:ok, _} = StripeManaged.Subscription.retrieve("sub_1")
  end

  test "Subscription.update/2 with default opts" do
    assert {:ok, _} = StripeManaged.Subscription.update("sub_1", %{})
  end

  test "Subscription.cancel/1 with default opts" do
    assert {:ok, _} = StripeManaged.Subscription.cancel("sub_1")
  end

  test "Subscription.resume/1 with default opts" do
    assert {:ok, _} = StripeManaged.Subscription.resume("sub_1")
  end

  test "Subscription.list/0 with default opts" do
    assert {:ok, _} = StripeManaged.Subscription.list()
  end

  test "Subscription.list_all/0 with default opts" do
    result = StripeManaged.Subscription.list_all() |> Enum.to_list()
    assert is_list(result)
  end

  # Invoice

  test "Invoice.retrieve/1 with default opts" do
    assert {:ok, _} = StripeManaged.Invoice.retrieve("in_1")
  end

  test "Invoice.list/0 with default opts" do
    assert {:ok, _} = StripeManaged.Invoice.list()
  end

  test "Invoice.list_all/0 with default opts" do
    result = StripeManaged.Invoice.list_all() |> Enum.to_list()
    assert is_list(result)
  end

  test "Invoice.upcoming/0 with default opts" do
    assert {:ok, _} = StripeManaged.Invoice.upcoming()
  end

  # Refund

  test "Refund.create/1 with default opts" do
    assert {:ok, _} = StripeManaged.Refund.create(%{payment_intent: "pi_1"})
  end

  test "Refund.retrieve/1 with default opts" do
    assert {:ok, _} = StripeManaged.Refund.retrieve("re_1")
  end

  test "Refund.update/2 with default opts" do
    assert {:ok, _} = StripeManaged.Refund.update("re_1", %{})
  end

  test "Refund.list/0 with default opts" do
    assert {:ok, _} = StripeManaged.Refund.list()
  end

  test "Refund.list_all/0 with default opts" do
    result = StripeManaged.Refund.list_all() |> Enum.to_list()
    assert is_list(result)
  end

  # Customer

  test "Customer.retrieve/1 with default opts" do
    assert {:ok, _} = StripeManaged.Customer.retrieve("cus_1")
  end

  test "Customer.list/0 with default opts" do
    assert {:ok, _} = StripeManaged.Customer.list()
  end

  test "Customer.list_all/0 with default opts" do
    result = StripeManaged.Customer.list_all() |> Enum.to_list()
    assert is_list(result)
  end

  # Client

  test "Client.get/1 with default opts" do
    assert {:ok, _} = StripeManaged.Client.get("/v1/products/prod_1")
  end

  test "Client.post/1 with default opts" do
    assert {:ok, _} = StripeManaged.Client.post("/v1/products", %{name: "Test"})
  end

  test "Client.delete/1 with default opts" do
    assert {:ok, _} = StripeManaged.Client.delete("/v1/products/prod_1")
  end
end
