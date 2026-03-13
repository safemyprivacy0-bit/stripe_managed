defmodule StripeManaged.Config do
  @moduledoc """
  Runtime configuration for the Stripe Managed Payments client.

  All values are read from application env at runtime (not compile-time).

  ## Options

    * `:api_key` - Stripe secret key (required)
    * `:api_version` - API version header (default: `"2025-03-31.basil"`)
    * `:base_url` - API base URL (default: `"https://api.stripe.com"`)
    * `:webhook_secret` - Webhook signing secret for signature verification
  """

  @default_api_version "2025-03-31.basil"
  @default_base_url "https://api.stripe.com"

  def api_key(opts \\ []) do
    get(:api_key, opts) || raise "Missing :api_key in :stripe_managed config"
  end

  def api_version(opts \\ []) do
    get(:api_version, opts) || @default_api_version
  end

  def base_url(opts \\ []) do
    get(:base_url, opts) || @default_base_url
  end

  def webhook_secret(opts \\ []) do
    get(:webhook_secret, opts)
  end

  defp get(key, opts) do
    Keyword.get(opts, key) || Application.get_env(:stripe_managed, key)
  end
end
