defmodule StripeManaged.Customer do
  @moduledoc """
  Retrieve customer records from Stripe.

  Customers are created automatically by Checkout Sessions.
  Managed Payments handles customer communication (receipts,
  renewal notices) through Link.

  Note: If a customer requests data deletion, Stripe cancels
  their subscriptions and deletes associated objects.
  """

  alias StripeManaged.Client

  @path "/v1/customers"

  @doc "Retrieves a customer by ID."
  @spec retrieve(String.t(), keyword()) :: Client.response()
  def retrieve(id, opts \\ []) do
    Client.get("#{@path}/#{id}", opts)
  end

  @doc "Lists customers."
  @spec list(map(), keyword()) :: Client.response()
  def list(params \\ %{}, opts \\ []) do
    Client.get(@path <> "?" <> URI.encode_query(Client.flatten_params(params)), opts)
  end

  @doc "Returns a lazy Stream of all customers, auto-paginating."
  @spec list_all(map(), keyword()) :: Enumerable.t()
  def list_all(params \\ %{}, opts \\ []) do
    Client.list_paginated(@path, params, opts)
  end
end
