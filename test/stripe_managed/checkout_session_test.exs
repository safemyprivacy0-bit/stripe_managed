defmodule StripeManaged.CheckoutSessionTest do
  use ExUnit.Case, async: false

  alias StripeManaged.{CheckoutSession, TestHelpers}

  setup do
    %{opts: TestHelpers.test_opts()}
  end

  test "create/2 returns session with URL", %{opts: opts} do
    params = %{
      line_items: [%{price: "price_test123", quantity: 1}],
      mode: "subscription",
      managed_payments: %{enabled: true},
      success_url: "https://example.com/success"
    }

    assert {:ok, session} = CheckoutSession.create(params, opts)
    assert session["id"] == "cs_test123"
    assert session["url"] =~ "checkout.stripe.com"
  end

  test "retrieve/2 returns session by ID", %{opts: opts} do
    assert {:ok, session} = CheckoutSession.retrieve("cs_test123", opts)
    assert session["status"] == "complete"
  end

  test "expire/2 expires the session", %{opts: opts} do
    assert {:ok, session} = CheckoutSession.expire("cs_test123", opts)
    assert session["status"] == "expired"
  end

  test "list_line_items/3 returns line items", %{opts: opts} do
    assert {:ok, result} = CheckoutSession.list_line_items("cs_test123", %{}, opts)
    assert result["object"] == "list"
    assert hd(result["data"])["quantity"] == 1
  end
end
