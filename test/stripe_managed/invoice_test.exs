defmodule StripeManaged.InvoiceTest do
  use ExUnit.Case, async: false

  alias StripeManaged.{Invoice, TestHelpers}

  setup do
    %{opts: TestHelpers.test_opts()}
  end

  describe "retrieve/2" do
    test "returns invoice with hosted URL", %{opts: opts} do
      assert {:ok, inv} = Invoice.retrieve("in_test123", opts)
      assert inv["id"] == "in_test123"
      assert inv["hosted_invoice_url"] =~ "invoice.stripe.com"
      assert inv["status"] == "paid"
    end
  end

  describe "list/2" do
    test "returns invoice list", %{opts: opts} do
      assert {:ok, result} = Invoice.list(%{}, opts)
      assert length(result["data"]) == 1
    end

    test "filters by subscription", %{opts: opts} do
      assert {:ok, result} = Invoice.list(%{subscription: "sub_test123"}, opts)
      assert is_list(result["data"])
    end

    test "filters by status", %{opts: opts} do
      assert {:ok, result} = Invoice.list(%{status: "paid"}, opts)
      assert is_list(result["data"])
    end
  end

  describe "list_all/2" do
    test "returns stream of invoices", %{opts: opts} do
      invoices = Invoice.list_all(%{}, opts) |> Enum.to_list()
      assert length(invoices) == 1
    end
  end

  describe "upcoming/2" do
    test "returns upcoming invoice", %{opts: opts} do
      assert {:ok, inv} = Invoice.upcoming(%{subscription: "sub_test123"}, opts)
      assert inv["amount_due"] == 2900
      assert inv["currency"] == "usd"
    end

    test "returns upcoming without params", %{opts: opts} do
      assert {:ok, inv} = Invoice.upcoming(%{}, opts)
      assert is_integer(inv["amount_due"])
    end
  end
end
