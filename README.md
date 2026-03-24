# StripeManaged

[![CI](https://github.com/safemyprivacy0-bit/stripe_managed/actions/workflows/ci.yml/badge.svg)](https://github.com/safemyprivacy0-bit/stripe_managed/actions/workflows/ci.yml)
[![Coverage](https://img.shields.io/badge/coverage-95%25-brightgreen)](https://github.com/safemyprivacy0-bit/stripe_managed)
[![Hex.pm](https://img.shields.io/hexpm/v/stripe_managed?color=purple)](https://hex.pm/packages/stripe_managed)
[![Hex Docs](https://img.shields.io/badge/hex-docs-blue)](https://hexdocs.pm/stripe_managed)
[![Elixir](https://img.shields.io/badge/elixir-1.16%2B-blueviolet)](https://elixir-lang.org/)
[![OTP](https://img.shields.io/badge/OTP-26%2B-blue)](https://www.erlang.org/)
[![License](https://img.shields.io/badge/license-MIT-lightgrey)](LICENSE)

Elixir client for [Stripe Managed Payments](https://docs.stripe.com/payments/managed-payments) - sell digital products with Stripe as your merchant of record.

Handles tax compliance (80+ countries), fraud prevention, and dispute management out of the box.

## Installation

Add to your `mix.exs`:

```elixir
{:stripe_managed, "~> 0.1"}
```

## Configuration

```elixir
config :stripe_managed,
  api_key: System.get_env("STRIPE_SECRET_KEY"),
  api_version: "2025-03-31.basil",
  webhook_secret: System.get_env("STRIPE_WEBHOOK_SECRET")
```

## Quick start

```elixir
# Create a product with a monthly price
{:ok, product} = StripeManaged.Product.create(%{
  name: "Pro Plan",
  tax_code: "txcd_10103001",
  default_price_data: %{
    unit_amount: 2900,
    currency: "usd",
    recurring: %{interval: "month"}
  }
})

# Start a checkout session (Stripe as merchant of record)
{:ok, session} = StripeManaged.CheckoutSession.create(%{
  line_items: [%{price: product.default_price, quantity: 1}],
  mode: "subscription",
  managed_payments: %{enabled: true},
  success_url: "https://yourapp.com/success"
})

# Redirect customer to session.url
```

## Supported resources

- `StripeManaged.Product` - products (digital goods, SaaS)
- `StripeManaged.Price` - pricing (one-time and recurring)
- `StripeManaged.CheckoutSession` - checkout sessions with managed payments
- `StripeManaged.Subscription` - subscription lifecycle
- `StripeManaged.Invoice` - invoices and hosted invoice URLs
- `StripeManaged.Refund` - refund management
- `StripeManaged.Customer` - customer records
- `StripeManaged.Webhook` - webhook signature verification and event parsing
- `StripeManaged.TaxCode` - eligible tax codes for digital products

## Webhook handling

```elixir
# In your Phoenix controller
def webhook(conn, _params) do
  payload = conn.assigns.raw_body
  signature = Plug.Conn.get_req_header(conn, "stripe-signature") |> List.first()

  case StripeManaged.Webhook.construct_event(payload, signature) do
    {:ok, event} ->
      handle_event(event)
      send_resp(conn, 200, "ok")

    {:error, reason} ->
      send_resp(conn, 400, reason)
  end
end
```

## License

MIT
