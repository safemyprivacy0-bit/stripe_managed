defmodule StripeManaged.Product do
  @moduledoc """
  Manage Stripe products for digital goods and SaaS.

  Products must use eligible tax codes for Managed Payments.
  See `StripeManaged.TaxCode` for the full list.

  ## Example

      {:ok, product} = StripeManaged.Product.create(%{
        name: "Pro Plan",
        description: "Full access to all features",
        tax_code: "txcd_10103001",
        default_price_data: %{
          unit_amount: 2900,
          currency: "usd",
          recurring: %{interval: "month"}
        }
      })
  """

  alias StripeManaged.Client

  @path "/v1/products"

  @doc "Creates a new product."
  @spec create(map(), keyword()) :: Client.response()
  def create(params, opts \\ []) do
    Client.post(@path, params, opts)
  end

  @doc "Retrieves a product by ID."
  @spec retrieve(String.t(), keyword()) :: Client.response()
  def retrieve(id, opts \\ []) do
    Client.get("#{@path}/#{id}", opts)
  end

  @doc "Updates a product."
  @spec update(String.t(), map(), keyword()) :: Client.response()
  def update(id, params, opts \\ []) do
    Client.post("#{@path}/#{id}", params, opts)
  end

  @doc "Deletes a product (only if it has no prices)."
  @spec delete(String.t(), keyword()) :: Client.response()
  def delete(id, opts \\ []) do
    Client.delete("#{@path}/#{id}", opts)
  end

  @doc "Lists products. Accepts optional filter params."
  @spec list(map(), keyword()) :: Client.response()
  def list(params \\ %{}, opts \\ []) do
    Client.get(@path <> "?" <> URI.encode_query(Client.flatten_params(params)), opts)
  end

  @doc "Returns a lazy Stream of all products, auto-paginating."
  @spec list_all(map(), keyword()) :: Enumerable.t()
  def list_all(params \\ %{}, opts \\ []) do
    Client.list_paginated(@path, params, opts)
  end
end
