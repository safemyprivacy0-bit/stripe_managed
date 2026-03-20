defmodule StripeManaged.CustomerTest do
  use ExUnit.Case, async: false

  alias StripeManaged.{Customer, TestHelpers}

  setup do
    %{opts: TestHelpers.test_opts()}
  end

  test "retrieve/2 returns customer", %{opts: opts} do
    assert {:ok, customer} = Customer.retrieve("cus_test123", opts)
    assert customer["id"] == "cus_test123"
    assert customer["email"] == "test@example.com"
  end

  test "list/2 returns customer list", %{opts: opts} do
    assert {:ok, result} = Customer.list(%{}, opts)
    assert length(result["data"]) == 1
  end
end
