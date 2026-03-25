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

Only `api_key` is required. Everything else has sensible defaults.

```elixir
config :stripe_managed,
  api_key: System.get_env("STRIPE_SECRET_KEY"),
  webhook_secret: System.get_env("STRIPE_WEBHOOK_SECRET")
```

| Option | Default | Description |
|--------|---------|-------------|
| `api_key` | *required* | Stripe secret key (`sk_live_...` or `sk_test_...`) |
| `webhook_secret` | `nil` | Webhook signing secret (`whsec_...`) |
| `api_version` | `"2025-03-31.basil"` | Stripe API version - only change if you know what you're doing |
| `base_url` | `"https://api.stripe.com"` | API base URL (override for testing) |

## Quick start

```elixir
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

# Create a checkout session with Stripe as merchant of record
{:ok, session} = StripeManaged.CheckoutSession.create(%{
  line_items: [%{price: product["default_price"], quantity: 1}],
  mode: "subscription",
  managed_payments: %{enabled: true},
  success_url: "https://yourapp.com/success"
})

# Redirect customer to session["url"]
```

## Managing subscriptions

```elixir
# Retrieve a subscription
{:ok, sub} = StripeManaged.Subscription.retrieve("sub_abc123")
sub["status"]           # => "active"
sub["current_period_end"] # => 1710000000

# Cancel at end of billing period
{:ok, _} = StripeManaged.Subscription.cancel("sub_abc123", %{
  cancel_at_period_end: true
})

# Upgrade - change price
{:ok, _} = StripeManaged.Subscription.update("sub_abc123", %{
  items: [%{id: "si_item123", price: "price_yearly"}],
  payment_behavior: "default_incomplete"
})

# List all active subscriptions
{:ok, result} = StripeManaged.Subscription.list(%{status: "active", limit: 20})
```

## Refunds

```elixir
# Full refund
{:ok, refund} = StripeManaged.Refund.create(%{payment_intent: "pi_abc123"})

# Partial refund (amount in cents)
{:ok, refund} = StripeManaged.Refund.create(%{
  payment_intent: "pi_abc123",
  amount: 1500,
  reason: "requested_by_customer"
})
```

## Invoices

```elixir
# Get invoice with hosted URL (for customer portal)
{:ok, invoice} = StripeManaged.Invoice.retrieve("in_abc123")
invoice["hosted_invoice_url"]  # => "https://invoice.stripe.com/i/..."

# Preview upcoming invoice for a subscription
{:ok, upcoming} = StripeManaged.Invoice.upcoming(%{subscription: "sub_abc123"})
upcoming["amount_due"]  # => 2900
```

## Tax codes

```elixir
# Check if your product type is eligible for Managed Payments
StripeManaged.TaxCode.eligible?("txcd_10103001")  # => true

# Common codes
StripeManaged.TaxCode.saas_personal()          # => "txcd_10103001"
StripeManaged.TaxCode.software_business()      # => "txcd_10101000"
StripeManaged.TaxCode.video_games_personal()   # => "txcd_10301001"
StripeManaged.TaxCode.online_courses_personal() # => "txcd_10501001"

# List all 30+ eligible codes
StripeManaged.TaxCode.all()
```

## Webhook handling

```elixir
# In your Phoenix controller
def webhook(conn, _params) do
  payload = conn.assigns.raw_body
  signature = Plug.Conn.get_req_header(conn, "stripe-signature") |> List.first()

  case StripeManaged.Webhook.construct_event(payload, signature) do
    {:ok, %{"type" => "checkout.session.completed"} = event} ->
      handle_checkout_completed(event)
      send_resp(conn, 200, "ok")

    {:ok, %{"type" => "customer.subscription.deleted"} = event} ->
      handle_subscription_canceled(event)
      send_resp(conn, 200, "ok")

    {:ok, _event} ->
      send_resp(conn, 200, "ok")

    {:error, reason} ->
      send_resp(conn, 400, reason)
  end
end
```

## Auto-pagination

All `list` calls return a single page. Use `list_all` to stream through all results:

```elixir
# Stream all products (fetches pages lazily)
StripeManaged.Product.list_all(%{active: true})
|> Stream.filter(fn p -> p["tax_code"] == "txcd_10103001" end)
|> Enum.to_list()
```

## Per-request config

Override config per call (useful for multi-tenant setups):

```elixir
{:ok, product} = StripeManaged.Product.retrieve("prod_abc", api_key: "sk_test_other_account")
```

## Supported resources

| Module | Description |
|--------|-------------|
| `StripeManaged.Product` | Products (digital goods, SaaS) |
| `StripeManaged.Price` | Pricing (one-time and recurring) |
| `StripeManaged.CheckoutSession` | Checkout with `managed_payments: %{enabled: true}` |
| `StripeManaged.Subscription` | Subscription lifecycle (update, cancel, resume) |
| `StripeManaged.Invoice` | Invoices with `hosted_invoice_url` |
| `StripeManaged.Refund` | Full and partial refunds |
| `StripeManaged.Customer` | Customer records |
| `StripeManaged.Webhook` | HMAC-SHA256 signature verification |
| `StripeManaged.TaxCode` | 30+ eligible digital product tax codes |

## License

MIT
