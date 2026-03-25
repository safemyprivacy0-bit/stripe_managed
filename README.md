# StripeManaged

[![CI](https://github.com/safemyprivacy0-bit/stripe_managed/actions/workflows/ci.yml/badge.svg)](https://github.com/safemyprivacy0-bit/stripe_managed/actions/workflows/ci.yml)
[![Coverage](https://img.shields.io/badge/coverage-95%25-brightgreen)](https://github.com/safemyprivacy0-bit/stripe_managed)
[![GitHub Release](https://img.shields.io/github/v/release/safemyprivacy0-bit/stripe_managed)](https://github.com/safemyprivacy0-bit/stripe_managed/releases)
[![Hex.pm](https://img.shields.io/hexpm/v/stripe_managed?color=purple)](https://hex.pm/packages/stripe_managed)
[![Hex Docs](https://img.shields.io/badge/hex-docs-blue)](https://hexdocs.pm/stripe_managed)
[![Elixir](https://img.shields.io/badge/elixir-1.16%2B-blueviolet)](https://elixir-lang.org/)
[![OTP](https://img.shields.io/badge/OTP-26%2B-blue)](https://www.erlang.org/)
[![License](https://img.shields.io/badge/license-MIT-lightgrey)](LICENSE)

Elixir client for [Stripe Managed Payments](https://docs.stripe.com/payments/managed-payments) - sell digital products with Stripe as your merchant of record.

Stripe handles tax compliance (80+ countries), fraud prevention, dispute management, and customer support. You handle products and checkout.

> **New here?** See [examples/selling_saas.md](examples/selling_saas.md) for a complete Phoenix integration guide - from setup to checkout to webhook handling.

## What is Stripe Managed Payments?

Stripe acts as the **merchant of record** for your digital product sales. This means:

- Stripe calculates, collects, and remits taxes in 80+ countries
- Stripe handles fraud prevention and dispute responses automatically
- Customers see "Sold through Link" at checkout
- Customers manage orders, payment methods, and refunds via the Link app
- You keep control of products, pricing, and subscription management

**Supported products**: SaaS, software downloads, video games, digital media, e-books, online courses, advertising services. Physical goods and services are not supported.

**Supported integration**: Stripe Checkout only (not Elements, Payment Links, or Connect).

## Installation

Add to your `mix.exs`:

```elixir
def deps do
  [
    {:stripe_managed, "~> 0.1"}
  ]
end
```

## Configuration

Only `api_key` is required. Everything else has sensible defaults.

```elixir
# config/runtime.exs
config :stripe_managed,
  api_key: System.get_env("STRIPE_SECRET_KEY"),
  webhook_secret: System.get_env("STRIPE_WEBHOOK_SECRET")
```

| Option | Default | Description |
|--------|---------|-------------|
| `api_key` | *required* | Stripe secret key (`sk_live_...` or `sk_test_...`) |
| `webhook_secret` | `nil` | Webhook signing secret (`whsec_...`), required for webhook verification |
| `api_version` | `"2025-03-31.basil"` | Stripe API version, only change if Stripe releases a newer one |
| `base_url` | `"https://api.stripe.com"` | API base URL, override for testing |

## Prerequisites

Before using this library:

1. Create a [Stripe account](https://dashboard.stripe.com/register)
2. Activate Managed Payments in your [Dashboard settings](https://dashboard.stripe.com/settings/managed-payments)
3. Accept the Managed Payments terms of service
4. Get your API keys from [Dashboard > Developers > API keys](https://dashboard.stripe.com/apikeys)

## Complete workflow

This is the typical flow for selling a digital product with Managed Payments:

### 1. Create a product with a price

Every product needs a [tax code](https://docs.stripe.com/tax/tax-codes) eligible for Managed Payments. Use `StripeManaged.TaxCode` to find the right one.

```elixir
# SaaS product with monthly billing
{:ok, product} = StripeManaged.Product.create(%{
  name: "Pro Plan",
  description: "Full access to all features",
  tax_code: StripeManaged.TaxCode.saas_personal(),
  default_price_data: %{
    unit_amount: 2900,
    currency: "usd",
    recurring: %{interval: "month"}
  }
})

product["id"]             # => "prod_abc123"
product["default_price"]  # => "price_xyz789"
```

You can also add extra prices to an existing product:

```elixir
# Add yearly price with discount
{:ok, yearly} = StripeManaged.Price.create(%{
  product: product["id"],
  unit_amount: 29000,
  currency: "usd",
  recurring: %{interval: "year"}
})
```

### 2. Create a checkout session

All Managed Payments sales go through Stripe Checkout. Set `managed_payments: %{enabled: true}` to activate merchant of record mode.

```elixir
# Subscription checkout
{:ok, session} = StripeManaged.CheckoutSession.create(%{
  line_items: [%{price: product["default_price"], quantity: 1}],
  mode: "subscription",
  managed_payments: %{enabled: true},
  success_url: "https://yourapp.com/success?session_id={CHECKOUT_SESSION_ID}",
  cancel_url: "https://yourapp.com/pricing"
})

# Redirect customer to Stripe Checkout
redirect(external: session["url"])
```

For one-time purchases (e.g. e-book, software download):

```elixir
{:ok, session} = StripeManaged.CheckoutSession.create(%{
  line_items: [%{price: "price_ebook", quantity: 1}],
  mode: "payment",
  managed_payments: %{enabled: true},
  success_url: "https://yourapp.com/download"
})
```

### 3. Handle the webhook

After payment, Stripe sends a `checkout.session.completed` event. Use it to provision access.

```elixir
# router.ex
post "/webhooks/stripe", StripeWebhookController, :handle

# stripe_webhook_controller.ex
defmodule MyAppWeb.StripeWebhookController do
  use MyAppWeb, :controller

  def handle(conn, _params) do
    payload = conn.assigns.raw_body
    signature = Plug.Conn.get_req_header(conn, "stripe-signature") |> List.first()

    case StripeManaged.Webhook.construct_event(payload, signature) do
      {:ok, %{"type" => "checkout.session.completed"} = event} ->
        session = event["data"]["object"]
        customer_id = session["customer"]
        subscription_id = session["subscription"]
        # Provision access for the customer
        MyApp.Billing.activate_subscription(customer_id, subscription_id)
        send_resp(conn, 200, "ok")

      {:ok, %{"type" => "customer.subscription.deleted"} = event} ->
        sub = event["data"]["object"]
        MyApp.Billing.deactivate_subscription(sub["id"])
        send_resp(conn, 200, "ok")

      {:ok, %{"type" => "invoice.payment_failed"} = event} ->
        invoice = event["data"]["object"]
        MyApp.Billing.handle_payment_failure(invoice["subscription"])
        send_resp(conn, 200, "ok")

      {:ok, _event} ->
        # Acknowledge events we don't handle
        send_resp(conn, 200, "ok")

      {:error, reason} ->
        send_resp(conn, 400, reason)
    end
  end
end
```

To receive the raw body for signature verification, add a body reader plug in your endpoint:

```elixir
# endpoint.ex
plug Plug.Parsers,
  parsers: [:urlencoded, :multipart, :json],
  pass: ["*/*"],
  body_reader: {MyAppWeb.CacheBodyReader, :read_body, []},
  json_decoder: Jason
```

```elixir
# lib/my_app_web/cache_body_reader.ex
defmodule MyAppWeb.CacheBodyReader do
  def read_body(conn, opts) do
    {:ok, body, conn} = Plug.Conn.read_body(conn, opts)
    conn = Plug.Conn.assign(conn, :raw_body, body)
    {:ok, body, conn}
  end
end
```

### 4. Manage subscriptions

```elixir
# Get subscription details
{:ok, sub} = StripeManaged.Subscription.retrieve("sub_abc123")
sub["status"]              # => "active"
sub["current_period_end"]  # => 1710000000 (Unix timestamp)

# Cancel at end of billing period (customer keeps access until then)
{:ok, canceled} = StripeManaged.Subscription.cancel("sub_abc123", %{
  cancel_at_period_end: true
})

# Cancel immediately
{:ok, canceled} = StripeManaged.Subscription.cancel("sub_abc123")

# Upgrade/downgrade - change price
{:ok, updated} = StripeManaged.Subscription.update("sub_abc123", %{
  items: [%{id: "si_item123", price: "price_yearly"}],
  payment_behavior: "default_incomplete"
})

# Resume a paused subscription
{:ok, resumed} = StripeManaged.Subscription.resume("sub_abc123")

# List all active subscriptions
{:ok, result} = StripeManaged.Subscription.list(%{status: "active", limit: 100})
result["data"]  # => [%{"id" => "sub_...", "status" => "active"}, ...]
```

### 5. Issue refunds

```elixir
# Full refund
{:ok, refund} = StripeManaged.Refund.create(%{
  payment_intent: "pi_abc123"
})

# Partial refund (amount in cents)
{:ok, refund} = StripeManaged.Refund.create(%{
  payment_intent: "pi_abc123",
  amount: 1500,
  reason: "requested_by_customer"
})

# Note: customers can also request refunds via Link support.
# Stripe may issue refunds at their discretion within 60 days.
```

### 6. Work with invoices

```elixir
# Get invoice with hosted URL (send to customer)
{:ok, invoice} = StripeManaged.Invoice.retrieve("in_abc123")
invoice["hosted_invoice_url"]  # => "https://invoice.stripe.com/i/..."
invoice["status"]              # => "paid"

# Preview next invoice amount before it's generated
{:ok, upcoming} = StripeManaged.Invoice.upcoming(%{subscription: "sub_abc123"})
upcoming["amount_due"]   # => 2900
upcoming["currency"]     # => "usd"

# List all invoices for a subscription
{:ok, result} = StripeManaged.Invoice.list(%{subscription: "sub_abc123"})
```

## Products and prices

```elixir
# Create product without inline price
{:ok, product} = StripeManaged.Product.create(%{
  name: "Starter Plan",
  tax_code: "txcd_10103001"
})

# Update product
{:ok, updated} = StripeManaged.Product.update(product["id"], %{
  name: "Starter Plan (Legacy)",
  active: false
})

# Retrieve product
{:ok, product} = StripeManaged.Product.retrieve("prod_abc123")

# Delete product (only if it has no prices)
{:ok, deleted} = StripeManaged.Product.delete("prod_abc123")

# List prices for a product
{:ok, result} = StripeManaged.Price.list(%{product: "prod_abc123"})

# Deactivate a price (cannot delete prices)
{:ok, _} = StripeManaged.Price.update("price_abc123", %{active: false})
```

## Customers

Customers are created automatically by Checkout Sessions. You can retrieve and list them:

```elixir
{:ok, customer} = StripeManaged.Customer.retrieve("cus_abc123")
customer["email"]  # => "user@example.com"

{:ok, result} = StripeManaged.Customer.list(%{email: "user@example.com"})
```

## Tax codes

Only products with eligible tax codes can be sold through Managed Payments. Each product you create must have a `tax_code` from this list.

```elixir
# SaaS for individuals (Notion, Spotify, Netflix)
StripeManaged.TaxCode.saas_personal()           # => "txcd_10103001"

# SaaS for companies (Slack, Jira, HubSpot)
StripeManaged.TaxCode.saas_business()           # => "txcd_10103000"

# Downloadable software for individuals
StripeManaged.TaxCode.software_personal()       # => "txcd_10101001"

# Downloadable software for businesses (IDE, design tools)
StripeManaged.TaxCode.software_business()       # => "txcd_10101000"

# Video games (Steam-style digital distribution)
StripeManaged.TaxCode.video_games_personal()    # => "txcd_10301001"

# E-books, digital publications
StripeManaged.TaxCode.ebooks_personal()         # => "txcd_10801001"

# Online courses, tutorials (Udemy, Coursera style)
StripeManaged.TaxCode.online_courses_personal() # => "txcd_10501001"

# Check if a code is eligible for Managed Payments
StripeManaged.TaxCode.eligible?("txcd_10103001")  # => true
StripeManaged.TaxCode.eligible?("txcd_99999999")  # => false

# Get human-readable description
StripeManaged.TaxCode.description("txcd_10103001")  # => "SaaS - personal use"

# Get all 30 codes as a map
StripeManaged.TaxCode.all()
# => %{"txcd_10103001" => "SaaS - personal use", ...}
```

> **Personal vs business?** Stripe uses `personal` (B2C) and `business` (B2B) variants.
> Most SaaS/apps use `personal` unless you only sell to companies.

<details>
<summary>Full list of 30 eligible codes</summary>

| Category | Code | Description |
|----------|------|-------------|
| **SaaS** | `txcd_10103001` | SaaS - personal use |
| | `txcd_10103000` | SaaS - business use |
| **Software** | `txcd_10101001` | Downloadable software - personal |
| | `txcd_10101000` | Downloadable software - business |
| | `txcd_10102001` | Custom software - personal |
| | `txcd_10102000` | Custom software - business |
| **Video games** | `txcd_10301001` | Video games - personal |
| | `txcd_10301000` | Video games - business |
| **Digital media** | `txcd_10201001` | Audio/visual works - personal |
| | `txcd_10201000` | Audio/visual works - business |
| | `txcd_10202001` | Audio works - personal |
| | `txcd_10202000` | Audio works - business |
| | `txcd_10203001` | Video works - personal |
| | `txcd_10203000` | Video works - business |
| **Digital artwork** | `txcd_10401001` | Digital artwork - personal |
| | `txcd_10401000` | Digital artwork - business |
| **E-books** | `txcd_10801001` | E-books - personal |
| | `txcd_10801000` | E-books - business |
| | `txcd_10802001` | Digital newspapers/magazines - personal |
| | `txcd_10802000` | Digital newspapers/magazines - business |
| **Online education** | `txcd_10501001` | Online courses - personal |
| | `txcd_10501000` | Online courses - business |
| | `txcd_10502001` | Training services - personal |
| | `txcd_10502000` | Training services - business |
| **Advertising** | `txcd_10601001` | Advertising services - personal |
| | `txcd_10601000` | Advertising services - business |
| **Information services** | `txcd_10701001` | Information services - personal |
| | `txcd_10701000` | Information services - business |
| | `txcd_10702001` | Website information services - personal |
| | `txcd_10702000` | Website information services - business |

</details>

## Auto-pagination

All `list/2` calls return a single page (default 10 items). Use `list_all/2` to stream through every result:

```elixir
# Stream all active products
StripeManaged.Product.list_all(%{active: true})
|> Stream.filter(fn p -> p["tax_code"] == "txcd_10103001" end)
|> Enum.to_list()

# Count all subscriptions
StripeManaged.Subscription.list_all(%{status: "active"})
|> Enum.count()
```

The stream fetches pages lazily - it only hits the API when you consume more items.

## Per-request config

Override global config on any call. Useful for multi-tenant setups or testing:

```elixir
# Use a different API key for this call
{:ok, product} = StripeManaged.Product.retrieve("prod_abc",
  api_key: "sk_test_other_account"
)

# Point at a local mock server
{:ok, product} = StripeManaged.Product.list(%{},
  api_key: "sk_test_fake",
  base_url: "http://localhost:4001"
)
```

## Error handling

All API calls return `{:ok, map()}` or `{:error, %StripeManaged.Error{}}`:

```elixir
case StripeManaged.Product.retrieve("prod_nonexistent") do
  {:ok, product} ->
    IO.puts(product["name"])

  {:error, %StripeManaged.Error{type: :invalid_request, message: msg}} ->
    IO.puts("Not found: #{msg}")

  {:error, %StripeManaged.Error{type: :authentication}} ->
    IO.puts("Bad API key")

  {:error, %StripeManaged.Error{type: :rate_limit}} ->
    IO.puts("Too many requests, slow down")

  {:error, %StripeManaged.Error{type: :network, message: msg}} ->
    IO.puts("Network issue: #{msg}")
end
```

Error types: `:api_error`, `:invalid_request`, `:authentication`, `:rate_limit`, `:card_error`, `:idempotency_error`, `:network`.

## Testing

The library ships with per-request config, so you can point it at a mock server in tests:

```elixir
# test/my_app/billing_test.exs
setup do
  # Start your mock or use the built-in mock server from this library
  %{opts: [api_key: "sk_test_fake", base_url: "http://localhost:#{port}"]}
end

test "creates checkout session", %{opts: opts} do
  {:ok, session} = StripeManaged.CheckoutSession.create(%{
    line_items: [%{price: "price_test", quantity: 1}],
    mode: "subscription",
    managed_payments: %{enabled: true},
    success_url: "http://localhost/success"
  }, opts)

  assert session["url"] =~ "checkout.stripe.com"
end
```

For integration tests against Stripe sandbox:

```elixir
# Run with: STRIPE_TEST_KEY=sk_test_... mix test --only integration
@moduletag :integration

test "full product lifecycle" do
  opts = [api_key: System.get_env("STRIPE_TEST_KEY")]

  {:ok, product} = StripeManaged.Product.create(%{
    name: "Test Product",
    tax_code: "txcd_10103001"
  }, opts)

  assert product["id"] =~ "prod_"
end
```

## Supported resources

| Module | Operations |
|--------|------------|
| `StripeManaged.Product` | create, retrieve, update, delete, list, list_all |
| `StripeManaged.Price` | create, retrieve, update, list, list_all |
| `StripeManaged.CheckoutSession` | create, retrieve, list, expire, list_line_items |
| `StripeManaged.Subscription` | retrieve, update, cancel, resume, list, list_all |
| `StripeManaged.Invoice` | retrieve, list, list_all, upcoming |
| `StripeManaged.Refund` | create, retrieve, update, list, list_all |
| `StripeManaged.Customer` | retrieve, list, list_all |
| `StripeManaged.Webhook` | construct_event, verify |
| `StripeManaged.TaxCode` | all, eligible?, description + helpers |

## License

MIT
