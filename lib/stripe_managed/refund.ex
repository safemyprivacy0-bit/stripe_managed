defmodule StripeManaged.Refund do
  @moduledoc """
  Issue and manage refunds for Managed Payments transactions.

  When refunds are processed, customers receive the full amount including
  original sales tax. Stripe retains and remits tax in certain jurisdictions.

  Note: Customers can also request refunds via Link support.
  Stripe may issue refunds at their discretion within 60 days.
  """

  alias StripeManaged.Client

  @path "/v1/refunds"

  @doc """
  Creates a refund.

  Params:
    - `payment_intent` or `charge` - the payment to refund (one required)
    - `amount` - partial refund amount in cents (omit for full refund)
    - `reason` - `"duplicate"`, `"fraudulent"`, or `"requested_by_customer"`
    - `metadata` - key-value metadata
  """
  @spec create(map(), keyword()) :: Client.response()
  def create(params, opts \\ []) do
    Client.post(@path, params, opts)
  end

  @doc "Retrieves a refund by ID."
  @spec retrieve(String.t(), keyword()) :: Client.response()
  def retrieve(id, opts \\ []) do
    Client.get("#{@path}/#{id}", opts)
  end

  @doc "Updates a refund's metadata."
  @spec update(String.t(), map(), keyword()) :: Client.response()
  def update(id, params, opts \\ []) do
    Client.post("#{@path}/#{id}", params, opts)
  end

  @doc "Lists refunds. Filter by `payment_intent`, `charge`, etc."
  @spec list(map(), keyword()) :: Client.response()
  def list(params \\ %{}, opts \\ []) do
    Client.get(@path <> "?" <> URI.encode_query(Client.flatten_params(params)), opts)
  end

  @doc "Returns a lazy Stream of all refunds, auto-paginating."
  @spec list_all(map(), keyword()) :: Enumerable.t()
  def list_all(params \\ %{}, opts \\ []) do
    Client.list_paginated(@path, params, opts)
  end
end
