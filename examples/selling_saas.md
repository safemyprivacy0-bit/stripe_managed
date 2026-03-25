# Example: Selling a SaaS subscription with Stripe Managed Payments

This is a complete, working example of selling a SaaS subscription using
StripeManaged in a Phoenix application. Stripe acts as the merchant of record -
handling taxes, fraud, and disputes automatically.

## What we're building

A "Pro Plan" subscription at $29/month. After checkout, the customer gets
access to premium features. When they cancel, access continues until the
billing period ends.

## 1. Setup

```elixir
# mix.exs
defp deps do
  [
    {:stripe_managed, "~> 0.1"},
    {:phoenix, "~> 1.7"},
    # ...
  ]
end
```

```elixir
# config/runtime.exs
config :stripe_managed,
  api_key: System.get_env("STRIPE_SECRET_KEY"),
  webhook_secret: System.get_env("STRIPE_WEBHOOK_SECRET")
```

## 2. Create your product (run once, in seeds or iex)

```elixir
# priv/repo/seeds.exs or run in iex
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

IO.puts("Save these IDs in your config or database:")
IO.puts("Product: #{product["id"]}")
IO.puts("Price:   #{product["default_price"]}")
```

If you also want a yearly option:

```elixir
{:ok, yearly_price} = StripeManaged.Price.create(%{
  product: product["id"],
  unit_amount: 29000,
  currency: "usd",
  recurring: %{interval: "year"}
})

IO.puts("Yearly price: #{yearly_price["id"]}")
```

## 3. Start checkout from your controller

```elixir
# lib/my_app_web/controllers/billing_controller.ex
defmodule MyAppWeb.BillingController do
  use MyAppWeb, :controller

  @pro_monthly_price "price_1TEyZ2FBJlGUf8KybKixp9xz"

  def checkout(conn, _params) do
    user = conn.assigns.current_user

    {:ok, session} = StripeManaged.CheckoutSession.create(%{
      line_items: [%{price: @pro_monthly_price, quantity: 1}],
      mode: "subscription",
      managed_payments: %{enabled: true},
      success_url: url(~p"/billing/success?session_id={CHECKOUT_SESSION_ID}"),
      cancel_url: url(~p"/pricing"),
      customer_email: user.email,
      metadata: %{user_id: user.id}
    })

    redirect(conn, external: session["url"])
  end

  def success(conn, %{"session_id" => session_id}) do
    {:ok, session} = StripeManaged.CheckoutSession.retrieve(session_id)

    if session["payment_status"] == "paid" do
      render(conn, :success, subscription_id: session["subscription"])
    else
      redirect(conn, to: ~p"/pricing")
    end
  end
end
```

```elixir
# lib/my_app_web/router.ex
scope "/billing", MyAppWeb do
  pipe_through [:browser, :require_auth]

  get "/checkout", BillingController, :checkout
  get "/success", BillingController, :success
end

# Webhook route (no auth, raw body needed)
scope "/webhooks", MyAppWeb do
  pipe_through :api
  post "/stripe", WebhookController, :stripe
end
```

## 4. Handle webhooks

```elixir
# lib/my_app_web/controllers/webhook_controller.ex
defmodule MyAppWeb.WebhookController do
  use MyAppWeb, :controller

  def stripe(conn, _params) do
    payload = conn.assigns.raw_body
    signature = get_req_header(conn, "stripe-signature") |> List.first()

    case StripeManaged.Webhook.construct_event(payload, signature) do
      {:ok, event} ->
        handle_event(event)
        send_resp(conn, 200, "ok")

      {:error, reason} ->
        send_resp(conn, 400, reason)
    end
  end

  defp handle_event(%{"type" => "checkout.session.completed", "data" => %{"object" => session}}) do
    user_id = session["metadata"]["user_id"]
    subscription_id = session["subscription"]
    customer_id = session["customer"]

    # Save to your database
    MyApp.Billing.activate_pro(user_id, %{
      stripe_subscription_id: subscription_id,
      stripe_customer_id: customer_id,
      status: "active"
    })
  end

  defp handle_event(%{"type" => "customer.subscription.updated", "data" => %{"object" => sub}}) do
    MyApp.Billing.update_subscription_status(sub["id"], sub["status"])
  end

  defp handle_event(%{"type" => "customer.subscription.deleted", "data" => %{"object" => sub}}) do
    MyApp.Billing.deactivate_pro(sub["id"])
  end

  defp handle_event(%{"type" => "invoice.payment_failed", "data" => %{"object" => invoice}}) do
    MyApp.Billing.handle_payment_failure(invoice["subscription"])
  end

  defp handle_event(_event), do: :ok
end
```

Don't forget the raw body reader for signature verification:

```elixir
# lib/my_app_web/endpoint.ex
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

## 5. Manage subscriptions

```elixir
# lib/my_app/billing.ex
defmodule MyApp.Billing do
  def cancel_subscription(subscription_id) do
    # Cancel at end of period - user keeps access until then
    StripeManaged.Subscription.cancel(subscription_id, %{
      cancel_at_period_end: true
    })
  end

  def cancel_immediately(subscription_id) do
    StripeManaged.Subscription.cancel(subscription_id)
  end

  def get_subscription(subscription_id) do
    {:ok, sub} = StripeManaged.Subscription.retrieve(subscription_id)

    %{
      status: sub["status"],
      current_period_end: DateTime.from_unix!(sub["current_period_end"]),
      cancel_at_period_end: sub["cancel_at_period_end"]
    }
  end

  def get_invoices(subscription_id) do
    {:ok, result} = StripeManaged.Invoice.list(%{
      subscription: subscription_id,
      limit: 12
    })

    Enum.map(result["data"], fn inv ->
      %{
        date: DateTime.from_unix!(inv["created"]),
        amount: inv["amount_paid"],
        currency: inv["currency"],
        status: inv["status"],
        pdf: inv["hosted_invoice_url"]
      }
    end)
  end

  def issue_refund(payment_intent_id) do
    StripeManaged.Refund.create(%{payment_intent: payment_intent_id})
  end
end
```

## 6. Check access in your app

```elixir
# lib/my_app_web/plugs/require_pro.ex
defmodule MyAppWeb.Plugs.RequirePro do
  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    user = conn.assigns.current_user

    if MyApp.Billing.pro?(user) do
      conn
    else
      conn
      |> put_flash(:error, "This feature requires a Pro subscription")
      |> redirect(to: "/pricing")
      |> halt()
    end
  end
end
```

## What Stripe handles for you

After this setup, Stripe automatically:

- Calculates and collects the right tax based on customer location
- Sends payment receipts and renewal notifications
- Handles disputes and fraud prevention
- Provides customers with order management via the Link app
- Processes refund requests (customers can also request via Link support)

You only need to:

- Create products/prices
- Redirect to checkout
- Handle webhook events
- Check subscription status in your app
