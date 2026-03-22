defmodule StripeManaged.CheckoutSessionTest do
  use ExUnit.Case, async: false

  alias StripeManaged.{CheckoutSession, TestHelpers}

  setup do
    %{opts: TestHelpers.test_opts()}
  end

  describe "create/2" do
    test "creates subscription session", %{opts: opts} do
      params = %{
        line_items: [%{price: "price_test123", quantity: 1}],
        mode: "subscription",
        managed_payments: %{enabled: true},
        success_url: "https://example.com/success"
      }

      assert {:ok, session} = CheckoutSession.create(params, opts)
      assert session["id"] == "cs_test123"
      assert session["url"] =~ "checkout.stripe.com"
      assert session["mode"] == "subscription"
    end

    test "creates one-time payment session", %{opts: opts} do
      params = %{
        line_items: [%{price: "price_test123", quantity: 1}],
        mode: "payment",
        managed_payments: %{enabled: true},
        success_url: "https://example.com/thanks"
      }

      assert {:ok, session} = CheckoutSession.create(params, opts)
      assert session["id"] == "cs_test123"
    end

    test "creates session with optional params", %{opts: opts} do
      params = %{
        line_items: [%{price: "price_test123", quantity: 1}],
        mode: "subscription",
        managed_payments: %{enabled: true},
        success_url: "https://example.com/success",
        cancel_url: "https://example.com/cancel",
        customer_email: "test@example.com",
        metadata: %{source: "web"}
      }

      assert {:ok, session} = CheckoutSession.create(params, opts)
      assert session["id"] == "cs_test123"
    end
  end

  describe "retrieve/2" do
    test "returns session by ID", %{opts: opts} do
      assert {:ok, session} = CheckoutSession.retrieve("cs_test123", opts)
      assert session["status"] == "complete"
      assert session["payment_status"] == "paid"
    end
  end

  describe "list/2" do
    test "lists sessions", %{opts: opts} do
      assert {:ok, _result} = CheckoutSession.list(%{}, opts)
    end
  end

  describe "expire/2" do
    test "expires the session", %{opts: opts} do
      assert {:ok, session} = CheckoutSession.expire("cs_test123", opts)
      assert session["status"] == "expired"
    end
  end

  describe "list_line_items/3" do
    test "returns line items for session", %{opts: opts} do
      assert {:ok, result} = CheckoutSession.list_line_items("cs_test123", %{}, opts)
      assert result["object"] == "list"
      items = result["data"]
      assert length(items) == 1
      assert hd(items)["quantity"] == 1
    end

    test "accepts pagination params", %{opts: opts} do
      assert {:ok, result} = CheckoutSession.list_line_items("cs_test123", %{limit: 5}, opts)
      assert result["object"] == "list"
    end
  end
end
