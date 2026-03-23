defmodule StripeManaged.IntegrationTest do
  @moduledoc """
  Integration tests against Stripe sandbox API.
  Skipped unless STRIPE_TEST_KEY is set.

  Run with: STRIPE_TEST_KEY=sk_test_... mix test --only integration
  """
  use ExUnit.Case, async: false

  @moduletag :integration

  setup do
    key = System.get_env("STRIPE_TEST_KEY")

    if is_nil(key) do
      :skip
    else
      %{opts: [api_key: key]}
    end
  end

  describe "Product lifecycle" do
    test "create, retrieve, update, list, delete", %{opts: opts} do
      # Create
      {:ok, product} =
        StripeManaged.Product.create(
          %{
            name: "Integration Test Product",
            description: "Created by test suite",
            default_price_data: %{
              unit_amount: 1999,
              currency: "usd",
              recurring: %{interval: "month"}
            }
          },
          opts
        )

      assert product["id"] =~ "prod_"
      assert product["name"] == "Integration Test Product"
      product_id = product["id"]

      # Retrieve
      {:ok, fetched} = StripeManaged.Product.retrieve(product_id, opts)
      assert fetched["id"] == product_id
      assert fetched["description"] == "Created by test suite"

      # Update
      {:ok, updated} =
        StripeManaged.Product.update(product_id, %{name: "Updated Product"}, opts)

      assert updated["name"] == "Updated Product"

      # List
      {:ok, list} = StripeManaged.Product.list(%{limit: 5}, opts)
      assert list["object"] == "list"
      ids = Enum.map(list["data"], & &1["id"])
      assert product_id in ids

      # Archive product (can't delete with prices, just deactivate)
      {:ok, archived} = StripeManaged.Product.update(product_id, %{active: false}, opts)
      assert archived["active"] == false
    end
  end

  describe "Price" do
    test "create and retrieve price for product", %{opts: opts} do
      # Create product first
      {:ok, product} =
        StripeManaged.Product.create(%{name: "Price Test Product"}, opts)

      product_id = product["id"]

      # Create price
      {:ok, price} =
        StripeManaged.Price.create(
          %{
            product: product_id,
            unit_amount: 4999,
            currency: "usd",
            recurring: %{interval: "year"}
          },
          opts
        )

      assert price["id"] =~ "price_"
      assert price["unit_amount"] == 4999
      assert price["currency"] == "usd"

      # Retrieve
      {:ok, fetched} = StripeManaged.Price.retrieve(price["id"], opts)
      assert fetched["product"] == product_id

      # List by product
      {:ok, list} = StripeManaged.Price.list(%{product: product_id}, opts)
      assert length(list["data"]) >= 1

      # Cleanup - archive product (prices stay)
      {:ok, _} = StripeManaged.Product.update(product_id, %{active: false}, opts)
    end
  end

  describe "Checkout Session" do
    test "create and retrieve checkout session", %{opts: opts} do
      # Create product with price
      {:ok, product} =
        StripeManaged.Product.create(
          %{
            name: "Checkout Test",
            default_price_data: %{unit_amount: 999, currency: "usd"}
          },
          opts
        )

      price_id = product["default_price"]

      # Create checkout session (one-time payment without managed_payments
      # since sandbox may not have it enabled)
      {:ok, session} =
        StripeManaged.CheckoutSession.create(
          %{
            line_items: [%{price: price_id, quantity: 1}],
            mode: "payment",
            success_url: "https://example.com/success"
          },
          opts
        )

      assert session["id"] =~ "cs_"
      assert session["url"] =~ "checkout.stripe.com"

      # Retrieve
      {:ok, fetched} = StripeManaged.CheckoutSession.retrieve(session["id"], opts)
      assert fetched["status"] == "open"

      # Expire
      {:ok, expired} = StripeManaged.CheckoutSession.expire(session["id"], opts)
      assert expired["status"] == "expired"

      # Cleanup - archive product
      {:ok, _} = StripeManaged.Product.update(product["id"], %{active: false}, opts)
    end
  end

  describe "Customer" do
    test "list customers", %{opts: opts} do
      {:ok, list} = StripeManaged.Customer.list(%{limit: 3}, opts)
      assert list["object"] == "list"
      assert is_list(list["data"])
    end
  end

  describe "Subscription" do
    test "list subscriptions", %{opts: opts} do
      {:ok, list} = StripeManaged.Subscription.list(%{limit: 3}, opts)
      assert list["object"] == "list"
      assert is_list(list["data"])
    end
  end

  describe "Invoice" do
    test "list invoices", %{opts: opts} do
      {:ok, list} = StripeManaged.Invoice.list(%{limit: 3}, opts)
      assert list["object"] == "list"
      assert is_list(list["data"])
    end
  end

  describe "Refund" do
    test "list refunds", %{opts: opts} do
      {:ok, list} = StripeManaged.Refund.list(%{limit: 3}, opts)
      assert list["object"] == "list"
      assert is_list(list["data"])
    end
  end
end
