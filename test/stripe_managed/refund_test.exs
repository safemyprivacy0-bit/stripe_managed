defmodule StripeManaged.RefundTest do
  use ExUnit.Case, async: false

  alias StripeManaged.{Refund, TestHelpers}

  setup do
    %{opts: TestHelpers.test_opts()}
  end

  describe "create/2" do
    test "creates full refund", %{opts: opts} do
      params = %{payment_intent: "pi_test123"}
      assert {:ok, refund} = Refund.create(params, opts)
      assert refund["id"] == "re_test123"
      assert refund["status"] == "succeeded"
    end

    test "creates partial refund", %{opts: opts} do
      params = %{payment_intent: "pi_test123", amount: 1500}
      assert {:ok, refund} = Refund.create(params, opts)
      assert refund["id"] == "re_test123"
    end

    test "creates refund with reason", %{opts: opts} do
      params = %{
        payment_intent: "pi_test123",
        reason: "requested_by_customer",
        metadata: %{note: "customer asked"}
      }

      assert {:ok, refund} = Refund.create(params, opts)
      assert refund["status"] == "succeeded"
    end
  end

  describe "retrieve/2" do
    test "returns refund by ID", %{opts: opts} do
      assert {:ok, refund} = Refund.retrieve("re_test123", opts)
      assert refund["amount"] == 2900
      assert refund["status"] == "succeeded"
    end
  end

  describe "update/3" do
    test "updates refund metadata", %{opts: opts} do
      assert {:ok, refund} = Refund.update("re_test123", %{metadata: %{reason: "duplicate"}}, opts)
      assert refund["id"] == "re_test123"
    end
  end

  describe "list/2" do
    test "returns refund list", %{opts: opts} do
      assert {:ok, result} = Refund.list(%{}, opts)
      assert length(result["data"]) == 1
    end

    test "filters by payment_intent", %{opts: opts} do
      assert {:ok, result} = Refund.list(%{payment_intent: "pi_test123"}, opts)
      assert is_list(result["data"])
    end
  end

  describe "list_all/2" do
    test "returns stream of refunds", %{opts: opts} do
      refunds = Refund.list_all(%{}, opts) |> Enum.to_list()
      assert length(refunds) == 1
    end
  end
end
