defmodule StripeManaged.SubscriptionTest do
  use ExUnit.Case, async: false

  alias StripeManaged.{Subscription, TestHelpers}

  setup do
    %{opts: TestHelpers.test_opts()}
  end

  test "retrieve/2 returns subscription", %{opts: opts} do
    assert {:ok, sub} = Subscription.retrieve("sub_test123", opts)
    assert sub["id"] == "sub_test123"
    assert sub["status"] == "active"
  end

  test "update/3 updates subscription", %{opts: opts} do
    assert {:ok, sub} = Subscription.update("sub_test123", %{metadata: %{plan: "pro"}}, opts)
    assert sub["status"] == "active"
  end

  test "cancel/3 cancels subscription", %{opts: opts} do
    assert {:ok, sub} = Subscription.cancel("sub_test123", %{}, opts)
    assert sub["status"] == "canceled"
  end

  test "resume/3 resumes subscription", %{opts: opts} do
    assert {:ok, sub} = Subscription.resume("sub_test123", %{}, opts)
    assert sub["status"] == "active"
  end

  test "list/2 returns subscriptions", %{opts: opts} do
    assert {:ok, result} = Subscription.list(%{}, opts)
    assert length(result["data"]) == 1
  end
end
