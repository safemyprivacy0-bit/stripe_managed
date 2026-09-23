defmodule StripeManaged.Subscription do
  @moduledoc """
  Manage subscriptions created through Managed Payments.

  Managed Payments subscriptions can originate from Checkout Sessions or
  Payment Links, but they aren't created directly through the Subscriptions API.
  Use this module to retrieve, update, and cancel existing subscriptions.

  Stripe supports eligible Subscription Items and eligible Invoice Items or
  Invoice Line Items on invoices for Managed Payments subscriptions.
  """

  alias StripeManaged.Client

  @path "/v1/subscriptions"

  @doc "Retrieves a subscription by ID."
  @spec retrieve(String.t(), keyword()) :: Client.response()
  def retrieve(id, opts \\ []) do
    Client.get(Client.path(@path, [id]), opts)
  end

  @doc """
  Updates a subscription.

  Supports changing prices (upgrade/downgrade), quantity, metadata,
  `proration_behavior` for proration control, and `payment_behavior`
  for handling payment failures on the update.
  """
  @spec update(String.t(), map(), keyword()) :: Client.response()
  def update(id, params, opts \\ []) do
    Client.post(Client.path(@path, [id]), params, opts)
  end

  @doc """
  Cancels a subscription.

  By default, cancels immediately (`DELETE /v1/subscriptions/:id`), accepting
  `invoice_now`, `prorate`, and `cancellation_details`.

  Pass `cancel_at_period_end: true` to cancel at the end of the current
  billing period instead. Stripe doesn't accept that parameter on the cancel
  endpoint, so this is sent as a subscription update. Use
  `update(id, %{cancel_at_period_end: false})` to undo a scheduled cancellation.
  """
  @spec cancel(String.t(), map(), keyword()) :: Client.response()
  def cancel(id, params \\ %{}, opts \\ []) do
    if Map.get(params, :cancel_at_period_end) || Map.get(params, "cancel_at_period_end") do
      update(id, params, opts)
    else
      Client.delete_with_params(Client.path(@path, [id]), params, opts)
    end
  end

  @doc "Lists subscriptions. Filter by `customer`, `price`, `status`, etc."
  @spec list(map(), keyword()) :: Client.response()
  def list(params \\ %{}, opts \\ []) do
    Client.get_with_params(@path, params, opts)
  end

  @doc "Returns a lazy Stream of all subscriptions, auto-paginating."
  @spec list_all(map(), keyword()) :: Enumerable.t()
  def list_all(params \\ %{}, opts \\ []) do
    Client.list_paginated(@path, params, opts)
  end

  @doc """
  Resumes a paused subscription (status `"paused"`).

  This doesn't undo `cancel_at_period_end`; use `update/3` with
  `cancel_at_period_end: false` for that.
  """
  @spec resume(String.t(), map(), keyword()) :: Client.response()
  def resume(id, params \\ %{}, opts \\ []) do
    Client.post(Client.path(@path, [id, "resume"]), params, opts)
  end
end
