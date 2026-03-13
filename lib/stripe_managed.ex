defmodule StripeManaged do
  @moduledoc """
  Elixir client for Stripe Managed Payments.

  Stripe Managed Payments lets you sell digital products (SaaS, software,
  digital content) with Stripe acting as the merchant of record - handling
  tax compliance in 80+ countries, fraud prevention, and dispute management.

  ## Configuration

      config :stripe_managed,
        api_key: "sk_test_...",
        api_version: "2025-03-31.basil",
        webhook_secret: "whsec_..."

  ## Usage

      # Create a product
      {:ok, product} = StripeManaged.Product.create(%{
        name: "Pro Plan",
        tax_code: "txcd_10103001",
        default_price_data: %{
          unit_amount: 2900,
          currency: "usd",
          recurring: %{interval: "month"}
        }
      })

      # Create a checkout session
      {:ok, session} = StripeManaged.CheckoutSession.create(%{
        line_items: [%{price: product.default_price, quantity: 1}],
        mode: "subscription",
        managed_payments: %{enabled: true},
        success_url: "https://example.com/success"
      })
  """
end
