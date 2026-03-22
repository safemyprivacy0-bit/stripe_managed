defmodule StripeManaged.ConfigTest do
  use ExUnit.Case, async: false

  alias StripeManaged.Config

  describe "api_key/1" do
    test "reads from opts" do
      assert Config.api_key(api_key: "sk_test") == "sk_test"
    end

    test "reads from application env" do
      Application.put_env(:stripe_managed, :api_key, "sk_from_env")
      assert Config.api_key([]) == "sk_from_env"
      Application.delete_env(:stripe_managed, :api_key)
    end

    test "works with no arguments (default opts)" do
      Application.put_env(:stripe_managed, :api_key, "sk_default")
      assert Config.api_key() == "sk_default"
      Application.delete_env(:stripe_managed, :api_key)
    end

    test "opts take precedence over application env" do
      Application.put_env(:stripe_managed, :api_key, "sk_from_env")
      assert Config.api_key(api_key: "sk_from_opts") == "sk_from_opts"
      Application.delete_env(:stripe_managed, :api_key)
    end

    test "raises when missing" do
      Application.delete_env(:stripe_managed, :api_key)

      assert_raise RuntimeError, ~r/Missing :api_key/, fn ->
        Config.api_key([])
      end
    end
  end

  describe "api_version/1" do
    test "defaults to basil" do
      assert Config.api_version([]) == "2025-03-31.basil"
    end

    test "works with no arguments" do
      assert Config.api_version() == "2025-03-31.basil"
    end

    test "can be overridden via opts" do
      assert Config.api_version(api_version: "2026-03-04.preview") == "2026-03-04.preview"
    end

    test "can be overridden via application env" do
      Application.put_env(:stripe_managed, :api_version, "custom")
      assert Config.api_version([]) == "custom"
      Application.delete_env(:stripe_managed, :api_version)
    end
  end

  describe "base_url/1" do
    test "defaults to stripe.com" do
      assert Config.base_url([]) == "https://api.stripe.com"
    end

    test "works with no arguments" do
      assert Config.base_url() == "https://api.stripe.com"
    end

    test "can be overridden" do
      assert Config.base_url(base_url: "http://localhost:4001") == "http://localhost:4001"
    end
  end

  describe "webhook_secret/1" do
    test "returns nil when not set" do
      assert Config.webhook_secret([]) == nil
    end

    test "works with no arguments" do
      assert Config.webhook_secret() == nil
    end

    test "reads from opts" do
      assert Config.webhook_secret(webhook_secret: "whsec_test") == "whsec_test"
    end

    test "reads from application env" do
      Application.put_env(:stripe_managed, :webhook_secret, "whsec_env")
      assert Config.webhook_secret([]) == "whsec_env"
      Application.delete_env(:stripe_managed, :webhook_secret)
    end
  end
end
