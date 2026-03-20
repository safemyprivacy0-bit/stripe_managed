defmodule StripeManaged.RefundTest do
  use ExUnit.Case, async: false

  alias StripeManaged.{Refund, TestHelpers}

  setup do
    %{opts: TestHelpers.test_opts()}
  end

  test "create/2 returns refund", %{opts: opts} do
    params = %{payment_intent: "pi_test123", amount: 1500}
    assert {:ok, refund} = Refund.create(params, opts)
    assert refund["id"] == "re_test123"
    assert refund["status"] == "succeeded"
  end

  test "retrieve/2 returns refund by ID", %{opts: opts} do
    assert {:ok, refund} = Refund.retrieve("re_test123", opts)
    assert refund["amount"] == 2900
  end

  test "list/2 returns refund list", %{opts: opts} do
    assert {:ok, result} = Refund.list(%{}, opts)
    assert length(result["data"]) == 1
  end
end
