defmodule StripeManaged.Subscription do
  @moduledoc """
  Manage subscriptions created through Managed Payments.

  Subscriptions are created via Checkout Sessions, not directly.
  Use this module to retrieve, update, and cancel existing subscriptions.

  Note: Invoice Items cannot be attached to Managed Payments subscriptions.
  All sales must originate from Checkout Sessions.
  """

  alias StripeManaged.Client

  @path "/v1/subscriptions"

  @doc "Retrieves a subscription by ID."
  @spec retrieve(String.t(), keyword()) :: Client.response()
  def retrieve(id, opts \\ []) do
    Client.get("#{@path}/#{id}", opts)
  end

  @doc """
  Updates a subscription.

  Supports changing prices (upgrade/downgrade), quantity, metadata,
  and `payment_behavior` for proration control.
  """
  @spec update(String.t(), map(), keyword()) :: Client.response()
  def update(id, params, opts \\ []) do
    Client.post("#{@path}/#{id}", params, opts)
  end

  @doc """
  Cancels a subscription.

  By default, cancels immediately. Pass `cancel_at_period_end: true`
  to cancel at the end of the current billing period instead.
  """
  @spec cancel(String.t(), map(), keyword()) :: Client.response()
  def cancel(id, params \\ %{}, opts \\ []) do
    Client.delete("#{@path}/#{id}?" <> URI.encode_query(Client.flatten_params(params)), opts)
  end

  @doc "Lists subscriptions. Filter by `customer`, `price`, `status`, etc."
  @spec list(map(), keyword()) :: Client.response()
  def list(params \\ %{}, opts \\ []) do
    Client.get(@path <> "?" <> URI.encode_query(Client.flatten_params(params)), opts)
  end

  @doc "Returns a lazy Stream of all subscriptions, auto-paginating."
  @spec list_all(map(), keyword()) :: Enumerable.t()
  def list_all(params \\ %{}, opts \\ []) do
    Client.list_paginated(@path, params, opts)
  end

  @doc "Resumes a paused subscription."
  @spec resume(String.t(), map(), keyword()) :: Client.response()
  def resume(id, params \\ %{}, opts \\ []) do
    Client.post("#{@path}/#{id}/resume", params, opts)
  end
end
