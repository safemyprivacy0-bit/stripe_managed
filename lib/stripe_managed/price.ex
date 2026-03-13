defmodule StripeManaged.Price do
  @moduledoc """
  Manage prices for Stripe products.

  Each product can have multiple prices (monthly, yearly, etc.).
  Tax behavior defaults to `exclusive` in Managed Payments
  (tax added on top of the stated price).

  ## Example

      {:ok, price} = StripeManaged.Price.create(%{
        product: "prod_abc123",
        unit_amount: 29900,
        currency: "usd",
        recurring: %{interval: "year"},
        tax_behavior: "exclusive"
      })
  """

  alias StripeManaged.Client

  @path "/v1/prices"

  @doc "Creates a new price."
  @spec create(map(), keyword()) :: Client.response()
  def create(params, opts \\ []) do
    Client.post(@path, params, opts)
  end

  @doc "Retrieves a price by ID."
  @spec retrieve(String.t(), keyword()) :: Client.response()
  def retrieve(id, opts \\ []) do
    Client.get("#{@path}/#{id}", opts)
  end

  @doc "Updates a price. Only `active`, `metadata`, `nickname`, and `tax_behavior` can be updated."
  @spec update(String.t(), map(), keyword()) :: Client.response()
  def update(id, params, opts \\ []) do
    Client.post("#{@path}/#{id}", params, opts)
  end

  @doc "Lists prices. Accepts optional filter params like `product`."
  @spec list(map(), keyword()) :: Client.response()
  def list(params \\ %{}, opts \\ []) do
    Client.get(@path <> "?" <> URI.encode_query(Client.flatten_params(params)), opts)
  end

  @doc "Returns a lazy Stream of all prices, auto-paginating."
  @spec list_all(map(), keyword()) :: Enumerable.t()
  def list_all(params \\ %{}, opts \\ []) do
    Client.list_paginated(@path, params, opts)
  end
end
