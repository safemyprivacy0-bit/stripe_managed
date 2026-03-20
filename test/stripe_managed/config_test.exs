defmodule StripeManaged.ConfigTest do
  use ExUnit.Case, async: true

  alias StripeManaged.Config

  test "api_key/1 reads from opts" do
    assert Config.api_key(api_key: "sk_test") == "sk_test"
  end

  test "api_key/1 raises when missing" do
    assert_raise RuntimeError, ~r/Missing :api_key/, fn ->
      Config.api_key([])
    end
  end

  test "api_version/1 defaults to basil" do
    assert Config.api_version([]) == "2025-03-31.basil"
  end

  test "api_version/1 can be overridden" do
    assert Config.api_version(api_version: "2026-03-04.preview") == "2026-03-04.preview"
  end

  test "base_url/1 defaults to stripe.com" do
    assert Config.base_url([]) == "https://api.stripe.com"
  end

  test "base_url/1 can be overridden" do
    assert Config.base_url(base_url: "http://localhost:4001") == "http://localhost:4001"
  end
end
