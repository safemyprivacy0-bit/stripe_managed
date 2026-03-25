defmodule StripeManaged do
  @moduledoc """
  Elixir client for Stripe Managed Payments.

  Stripe Managed Payments lets you sell digital products (SaaS, software,
  digital content) with Stripe acting as the merchant of record - handling
  tax compliance in 80+ countries, fraud prevention, and dispute management.

  ## Configuration

      # Required
      config :stripe_managed,
        api_key: System.get_env("STRIPE_SECRET_KEY")

      # Optional
      config :stripe_managed,
        webhook_secret: System.get_env("STRIPE_WEBHOOK_SECRET"),
        api_version: "2025-03-31.basil"  # default, rarely needs changing

  ## Usage

      # Create a product with a recurring price
      {:ok, product} = StripeManaged.Product.create(%{
        name: "Pro Plan",
        tax_code: "txcd_10103001",
        default_price_data: %{
          unit_amount: 2900,
          currency: "usd",
          recurring: %{interval: "month"}
        }
      })

      # Create a checkout session (Stripe as merchant of record)
      {:ok, session} = StripeManaged.CheckoutSession.create(%{
        line_items: [%{price: product["default_price"], quantity: 1}],
        mode: "subscription",
        managed_payments: %{enabled: true},
        success_url: "https://example.com/success"
      })

      # Redirect customer to session["url"]

      # Later: manage subscriptions, refunds, invoices
      {:ok, sub} = StripeManaged.Subscription.retrieve("sub_...")
      {:ok, _} = StripeManaged.Subscription.cancel("sub_...", %{cancel_at_period_end: true})
      {:ok, _} = StripeManaged.Refund.create(%{payment_intent: "pi_..."})
  """
end
