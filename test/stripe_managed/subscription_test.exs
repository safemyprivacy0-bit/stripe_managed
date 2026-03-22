defmodule StripeManaged.SubscriptionTest do
  use ExUnit.Case, async: false

  alias StripeManaged.{Subscription, TestHelpers}

  setup do
    %{opts: TestHelpers.test_opts()}
  end

  describe "retrieve/2" do
    test "returns subscription by ID", %{opts: opts} do
      assert {:ok, sub} = Subscription.retrieve("sub_test123", opts)
      assert sub["id"] == "sub_test123"
      assert sub["status"] == "active"
      assert sub["current_period_end"] == 1_710_000_000
    end
  end

  describe "update/3" do
    test "updates subscription metadata", %{opts: opts} do
      assert {:ok, sub} = Subscription.update("sub_test123", %{metadata: %{plan: "pro"}}, opts)
      assert sub["status"] == "active"
    end

    test "updates subscription price (upgrade)", %{opts: opts} do
      params = %{
        items: [%{id: "si_test", price: "price_new"}],
        payment_behavior: "default_incomplete"
      }

      assert {:ok, sub} = Subscription.update("sub_test123", params, opts)
      assert sub["id"] == "sub_test123"
    end
  end

  describe "cancel/3" do
    test "cancels subscription immediately", %{opts: opts} do
      assert {:ok, sub} = Subscription.cancel("sub_test123", %{}, opts)
      assert sub["status"] == "canceled"
    end

    test "cancels at period end", %{opts: opts} do
      assert {:ok, sub} = Subscription.cancel("sub_test123", %{cancel_at_period_end: true}, opts)
      assert sub["status"] == "canceled"
    end
  end

  describe "resume/3" do
    test "resumes paused subscription", %{opts: opts} do
      assert {:ok, sub} = Subscription.resume("sub_test123", %{}, opts)
      assert sub["status"] == "active"
    end
  end

  describe "list/2" do
    test "returns subscription list", %{opts: opts} do
      assert {:ok, result} = Subscription.list(%{}, opts)
      assert length(result["data"]) == 1
    end

    test "filters by status", %{opts: opts} do
      assert {:ok, result} = Subscription.list(%{status: "active"}, opts)
      assert is_list(result["data"])
    end
  end

  describe "list_all/2" do
    test "returns stream of subscriptions", %{opts: opts} do
      subs = Subscription.list_all(%{}, opts) |> Enum.to_list()
      assert length(subs) == 1
    end
  end
end
