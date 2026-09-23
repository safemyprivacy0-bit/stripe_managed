defmodule StripeManaged.BillingPortalTest do
  use ExUnit.Case, async: false

  alias StripeManaged.{BillingPortal, TestHelpers}

  setup do
    %{opts: TestHelpers.test_opts()}
  end

  describe "create_session/2" do
    test "creates a portal session", %{opts: opts} do
      params = %{customer: "cus_abc", return_url: "https://example.com/settings/billing"}

      assert {:ok, session} = BillingPortal.create_session(params, opts)
      assert session["object"] == "billing_portal.session"
      assert session["customer"] == "cus_abc"
      assert session["return_url"] == "https://example.com/settings/billing"
      assert session["url"] =~ "billing.stripe.com"
    end

    test "encodes nested flow_data", %{opts: opts} do
      opts = Keyword.put(opts, :base_url, opts[:base_url] <> "/v1/echo")

      params = %{
        customer: "cus_abc",
        flow_data: %{
          type: "subscription_cancel",
          subscription_cancel: %{subscription: "sub_123"}
        }
      }

      assert {:ok, echo} = BillingPortal.create_session(params, opts)
      assert echo["method"] == "POST"
      assert echo["request_path"] == "/v1/echo/v1/billing_portal/sessions"

      assert echo["body_params"] == %{
               "customer" => "cus_abc",
               "flow_data" => %{
                 "type" => "subscription_cancel",
                 "subscription_cancel" => %{"subscription" => "sub_123"}
               }
             }
    end
  end
end
