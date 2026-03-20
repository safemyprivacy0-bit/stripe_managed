defmodule StripeManaged.MockServer do
  @moduledoc """
  A Plug-based mock server for testing Stripe API calls.

  Starts a Bandit/Cowboy server on a random port and intercepts
  requests to return fixture data.
  """

  use Plug.Router

  plug :match
  plug Plug.Parsers, parsers: [:urlencoded, :json], json_decoder: Jason
  plug :dispatch

  # -- Products --

  post "/v1/products" do
    json(conn, 200, %{
      "id" => "prod_test123",
      "object" => "product",
      "name" => conn.body_params["name"] || "Test Product",
      "description" => conn.body_params["description"],
      "tax_code" => conn.body_params["tax_code"],
      "default_price" => "price_test123",
      "active" => true,
      "created" => 1_700_000_000
    })
  end

  get "/v1/products/:id" do
    json(conn, 200, %{
      "id" => id,
      "object" => "product",
      "name" => "Test Product",
      "active" => true,
      "created" => 1_700_000_000
    })
  end

  delete "/v1/products/:id" do
    json(conn, 200, %{"id" => id, "object" => "product", "deleted" => true})
  end

  get "/v1/products" do
    json(conn, 200, %{
      "object" => "list",
      "data" => [
        %{"id" => "prod_1", "object" => "product", "name" => "Product 1"},
        %{"id" => "prod_2", "object" => "product", "name" => "Product 2"}
      ],
      "has_more" => false
    })
  end

  # -- Prices --

  post "/v1/prices" do
    json(conn, 200, %{
      "id" => "price_test123",
      "object" => "price",
      "product" => conn.body_params["product"] || "prod_test123",
      "unit_amount" => conn.body_params["unit_amount"] || "2900",
      "currency" => conn.body_params["currency"] || "usd",
      "active" => true
    })
  end

  get "/v1/prices/:id" do
    json(conn, 200, %{
      "id" => id,
      "object" => "price",
      "unit_amount" => 2900,
      "currency" => "usd"
    })
  end

  get "/v1/prices" do
    json(conn, 200, %{
      "object" => "list",
      "data" => [%{"id" => "price_1", "object" => "price", "unit_amount" => 2900}],
      "has_more" => false
    })
  end

  # -- Checkout Sessions --

  post "/v1/checkout/sessions" do
    json(conn, 200, %{
      "id" => "cs_test123",
      "object" => "checkout.session",
      "url" => "https://checkout.stripe.com/c/pay/cs_test123",
      "mode" => conn.body_params["mode"] || "subscription",
      "status" => "open",
      "payment_status" => "unpaid"
    })
  end

  get "/v1/checkout/sessions/:id" do
    json(conn, 200, %{
      "id" => id,
      "object" => "checkout.session",
      "status" => "complete",
      "payment_status" => "paid"
    })
  end

  post "/v1/checkout/sessions/:id/expire" do
    json(conn, 200, %{
      "id" => id,
      "object" => "checkout.session",
      "status" => "expired"
    })
  end

  get "/v1/checkout/sessions/:_id/line_items" do
    json(conn, 200, %{
      "object" => "list",
      "data" => [%{"id" => "li_1", "price" => %{"id" => "price_1"}, "quantity" => 1}],
      "has_more" => false
    })
  end

  # -- Subscriptions --

  get "/v1/subscriptions/:id" do
    json(conn, 200, %{
      "id" => id,
      "object" => "subscription",
      "status" => "active",
      "current_period_end" => 1_710_000_000
    })
  end

  post "/v1/subscriptions/:id" do
    json(conn, 200, %{
      "id" => id,
      "object" => "subscription",
      "status" => "active"
    })
  end

  delete "/v1/subscriptions/:_id" do
    json(conn, 200, %{
      "id" => "sub_test123",
      "object" => "subscription",
      "status" => "canceled"
    })
  end

  post "/v1/subscriptions/:id/resume" do
    json(conn, 200, %{
      "id" => id,
      "object" => "subscription",
      "status" => "active"
    })
  end

  get "/v1/subscriptions" do
    json(conn, 200, %{
      "object" => "list",
      "data" => [%{"id" => "sub_1", "object" => "subscription", "status" => "active"}],
      "has_more" => false
    })
  end

  # -- Invoices --

  get "/v1/invoices/upcoming" do
    json(conn, 200, %{
      "object" => "invoice",
      "amount_due" => 2900,
      "currency" => "usd",
      "status" => "draft"
    })
  end

  get "/v1/invoices/:id" do
    json(conn, 200, %{
      "id" => id,
      "object" => "invoice",
      "hosted_invoice_url" => "https://invoice.stripe.com/i/inv_test",
      "status" => "paid"
    })
  end

  get "/v1/invoices" do
    json(conn, 200, %{
      "object" => "list",
      "data" => [%{"id" => "in_1", "object" => "invoice", "status" => "paid"}],
      "has_more" => false
    })
  end

  # -- Refunds --

  post "/v1/refunds" do
    json(conn, 200, %{
      "id" => "re_test123",
      "object" => "refund",
      "amount" => conn.body_params["amount"] || "2900",
      "status" => "succeeded",
      "payment_intent" => conn.body_params["payment_intent"]
    })
  end

  get "/v1/refunds/:id" do
    json(conn, 200, %{
      "id" => id,
      "object" => "refund",
      "amount" => 2900,
      "status" => "succeeded"
    })
  end

  get "/v1/refunds" do
    json(conn, 200, %{
      "object" => "list",
      "data" => [%{"id" => "re_1", "object" => "refund", "status" => "succeeded"}],
      "has_more" => false
    })
  end

  # -- Customers --

  get "/v1/customers/:id" do
    json(conn, 200, %{
      "id" => id,
      "object" => "customer",
      "email" => "test@example.com"
    })
  end

  get "/v1/customers" do
    json(conn, 200, %{
      "object" => "list",
      "data" => [%{"id" => "cus_1", "object" => "customer", "email" => "test@example.com"}],
      "has_more" => false
    })
  end

  # -- Error routes --

  match "/v1/error/404" do
    json(conn, 404, %{
      "error" => %{
        "type" => "invalid_request_error",
        "code" => "resource_missing",
        "message" => "No such product: 'prod_missing'"
      }
    })
  end

  match "/v1/error/401" do
    json(conn, 401, %{
      "error" => %{
        "type" => "authentication_error",
        "message" => "Invalid API Key provided"
      }
    })
  end

  match _ do
    json(conn, 404, %{"error" => %{"type" => "invalid_request_error", "message" => "Not found"}})
  end

  defp json(conn, status, body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(body))
  end
end
