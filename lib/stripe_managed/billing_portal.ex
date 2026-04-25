defmodule StripeManaged.BillingPortal do
  @moduledoc """
  Create Stripe Billing Portal Sessions.

  The portal lets customers manage subscriptions, payment methods,
  and view invoices without custom UI.

  ## Example

      {:ok, session} = StripeManaged.BillingPortal.create_session(%{
        customer: "cus_abc",
        return_url: "https://example.com/settings/billing"
      })

      # Redirect to session["url"]
  """

  alias StripeManaged.Client

  @path "/v1/billing_portal/sessions"

  @doc """
  Creates a new Billing Portal Session.

  Required params:
    - `customer` - Stripe customer ID

  Optional params:
    - `return_url` - URL to redirect after the customer leaves the portal
    - `configuration` - portal configuration ID (uses default if omitted)
    - `flow_data` - pre-select a specific flow (subscription cancellation, etc.)
  """
  @spec create_session(map(), keyword()) :: Client.response()
  def create_session(params, opts \\ []) do
    Client.post(@path, params, opts)
  end
end
