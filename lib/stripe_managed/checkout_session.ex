defmodule StripeManaged.CheckoutSession do
  @moduledoc """
  Create and manage Stripe Checkout Sessions with Managed Payments.

  This is the primary integration point - all Managed Payments sales
  must go through Checkout Sessions with `managed_payments: %{enabled: true}`.

  Supports both one-time payments (`mode: "payment"`) and
  subscriptions (`mode: "subscription"`).

  ## Example - subscription

      {:ok, session} = StripeManaged.CheckoutSession.create(%{
        line_items: [%{price: "price_abc", quantity: 1}],
        mode: "subscription",
        managed_payments: %{enabled: true},
        success_url: "https://example.com/success"
      })

      # Redirect to session["url"]

  ## Example - one-time payment

      {:ok, session} = StripeManaged.CheckoutSession.create(%{
        line_items: [%{price: "price_xyz", quantity: 1}],
        mode: "payment",
        managed_payments: %{enabled: true},
        success_url: "https://example.com/thanks"
      })
  """

  alias StripeManaged.Client

  @path "/v1/checkout/sessions"

  @doc """
  Creates a new Checkout Session.

  Required params:
    - `line_items` - list of `%{price: price_id, quantity: n}`
    - `mode` - `"subscription"` or `"payment"`
    - `managed_payments` - `%{enabled: true}`
    - `success_url` - redirect URL after successful payment

  Optional params:
    - `cancel_url` - redirect URL if customer cancels
    - `customer` - existing customer ID
    - `customer_email` - pre-fill email
    - `metadata` - key-value metadata
    - `saved_payment_method_options` - saved payment method config
    - `payment_method_collection` - `"if_required"` for free trials
  """
  @spec create(map(), keyword()) :: Client.response()
  def create(params, opts \\ []) do
    Client.post(@path, params, opts)
  end

  @doc "Retrieves a session by ID."
  @spec retrieve(String.t(), keyword()) :: Client.response()
  def retrieve(id, opts \\ []) do
    Client.get("#{@path}/#{id}", opts)
  end

  @doc "Lists checkout sessions."
  @spec list(map(), keyword()) :: Client.response()
  def list(params \\ %{}, opts \\ []) do
    Client.get(@path <> "?" <> URI.encode_query(Client.flatten_params(params)), opts)
  end

  @doc "Expires a checkout session so it can no longer be completed."
  @spec expire(String.t(), keyword()) :: Client.response()
  def expire(id, opts \\ []) do
    Client.post("#{@path}/#{id}/expire", %{}, opts)
  end

  @doc "Retrieves line items for a session."
  @spec list_line_items(String.t(), map(), keyword()) :: Client.response()
  def list_line_items(id, params \\ %{}, opts \\ []) do
    Client.get(
      "#{@path}/#{id}/line_items?" <> URI.encode_query(Client.flatten_params(params)),
      opts
    )
  end
end
