defmodule StripeManaged.InvoiceTest do
  use ExUnit.Case, async: false

  alias StripeManaged.{Invoice, TestHelpers}

  setup do
    %{opts: TestHelpers.test_opts()}
  end

  test "retrieve/2 returns invoice with hosted URL", %{opts: opts} do
    assert {:ok, inv} = Invoice.retrieve("in_test123", opts)
    assert inv["id"] == "in_test123"
    assert inv["hosted_invoice_url"] =~ "invoice.stripe.com"
  end

  test "list/2 returns invoice list", %{opts: opts} do
    assert {:ok, result} = Invoice.list(%{}, opts)
    assert length(result["data"]) == 1
  end

  test "upcoming/2 returns upcoming invoice", %{opts: opts} do
    assert {:ok, inv} = Invoice.upcoming(%{subscription: "sub_test123"}, opts)
    assert inv["amount_due"] == 2900
  end
end
