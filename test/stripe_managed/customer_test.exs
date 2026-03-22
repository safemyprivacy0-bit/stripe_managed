defmodule StripeManaged.CustomerTest do
  use ExUnit.Case, async: false

  alias StripeManaged.{Customer, TestHelpers}

  setup do
    %{opts: TestHelpers.test_opts()}
  end

  describe "retrieve/2" do
    test "returns customer by ID", %{opts: opts} do
      assert {:ok, customer} = Customer.retrieve("cus_test123", opts)
      assert customer["id"] == "cus_test123"
      assert customer["email"] == "test@example.com"
      assert customer["object"] == "customer"
    end
  end

  describe "list/2" do
    test "returns customer list", %{opts: opts} do
      assert {:ok, result} = Customer.list(%{}, opts)
      assert length(result["data"]) == 1
      assert hd(result["data"])["email"] == "test@example.com"
    end

    test "accepts filter params", %{opts: opts} do
      assert {:ok, result} = Customer.list(%{email: "test@example.com", limit: 5}, opts)
      assert is_list(result["data"])
    end
  end

  describe "list_all/2" do
    test "returns stream of customers", %{opts: opts} do
      customers = Customer.list_all(%{}, opts) |> Enum.to_list()
      assert length(customers) == 1
      assert hd(customers)["id"] == "cus_1"
    end
  end
end
