defmodule StripeManaged.Client do
  @moduledoc """
  HTTP client for the Stripe API.

  Handles authentication, request encoding, response parsing, and retries.
  All resource modules delegate to this module for actual HTTP calls.

  ## Request options

  Every function accepts a keyword list of options. Besides the config keys
  described in `StripeManaged.Config`, the following are supported:

    * `:idempotency_key` - `Idempotency-Key` header for POST requests.
      When omitted, a random key is generated per call so that automatic
      retries of a POST can never create duplicate objects.
    * `:max_retries` - retries for transient failures (default: `2`).
  """

  alias StripeManaged.{Config, Error}

  @type response :: {:ok, map()} | {:error, Error.t()}

  @doc """
  Performs a GET request.
  """
  @spec get(String.t(), keyword()) :: response()
  def get(path, opts \\ []) do
    request(:get, path, nil, opts)
  end

  @doc """
  Performs a GET request with `params` encoded as the query string.
  """
  @spec get_with_params(String.t(), map(), keyword()) :: response()
  def get_with_params(path, params, opts \\ []) do
    request(:get, path, params, opts)
  end

  @doc """
  Performs a POST request with form-encoded body.
  """
  @spec post(String.t(), map() | nil, keyword()) :: response()
  def post(path, params \\ nil, opts \\ []) do
    request(:post, path, params, opts)
  end

  @doc """
  Performs a DELETE request.
  """
  @spec delete(String.t(), keyword()) :: response()
  def delete(path, opts \\ []) do
    request(:delete, path, nil, opts)
  end

  @doc """
  Performs a DELETE request with `params` encoded as the query string.
  """
  @spec delete_with_params(String.t(), map(), keyword()) :: response()
  def delete_with_params(path, params, opts \\ []) do
    request(:delete, path, params, opts)
  end

  @doc """
  Lists resources with auto-pagination support.

  Returns a Stream that lazily fetches pages. If a page request fails,
  the stream emits a single `{:error, %StripeManaged.Error{}}` element
  and halts.
  """
  @spec list_paginated(String.t(), map(), keyword()) :: Enumerable.t()
  def list_paginated(path, params \\ %{}, opts \\ []) do
    Stream.resource(
      fn -> params end,
      fn
        nil ->
          {:halt, nil}

        params ->
          case get_with_params(path, params, opts) do
            {:ok, %{"data" => [_ | _] = data, "has_more" => true}} ->
              last_id = data |> List.last() |> Map.get("id")
              {data, put_starting_after(params, last_id)}

            {:ok, %{"data" => data}} when is_list(data) ->
              {data, nil}

            {:ok, body} ->
              {[{:error, Error.from_response(body, 200)}], nil}

            {:error, _} = error ->
              {[error], nil}
          end
      end,
      fn _ -> :ok end
    )
  end

  @doc """
  Builds a resource path, URL-encoding each dynamic segment.

      iex> StripeManaged.Client.path("/v1/customers", ["cus_123"])
      "/v1/customers/cus_123"

      iex> StripeManaged.Client.path("/v1/customers", ["../charges"])
      "/v1/customers/..%2Fcharges"

  Raises `ArgumentError` for a `nil` or empty segment, which would otherwise
  silently turn a retrieve into a list request.
  """
  @spec path(String.t(), [String.t()]) :: String.t()
  def path(base, segments) do
    Enum.reduce(segments, base, fn segment, acc ->
      acc <> "/" <> encode_segment(segment)
    end)
  end

  defp encode_segment(segment) when segment in [nil, ""] do
    raise ArgumentError, "expected a non-empty ID, got: #{inspect(segment)}"
  end

  defp encode_segment(segment) do
    URI.encode(to_string(segment), &URI.char_unreserved?/1)
  end

  # -- Private --

  defp request(method, path, params, opts) do
    req =
      Req.new(
        method: method,
        url: Config.base_url(opts) <> path,
        headers: headers(method, opts),
        retry: :transient,
        max_retries: Keyword.get(opts, :max_retries, 2),
        retry_delay: &retry_delay/1
      )
      |> put_params(method, params)

    case Req.request(req) do
      {:ok, %Req.Response{status: status, body: body}} when status in 200..299 ->
        {:ok, body}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, Error.from_response(body, status)}

      {:error, reason} ->
        {:error, Error.network_error(reason)}
    end
  end

  defp put_params(req, _method, nil), do: req
  defp put_params(req, :post, params), do: Req.merge(req, form: flatten_params(params))
  defp put_params(req, _method, params), do: Req.merge(req, params: flatten_params(params))

  defp headers(method, opts) do
    [
      {"authorization", "Bearer #{Config.api_key(opts)}"},
      {"stripe-version", Config.api_version(opts)}
    ] ++ idempotency_header(method, opts)
  end

  # The key is fixed before Req runs, so every retry of the same POST
  # carries the same key and Stripe deduplicates it.
  defp idempotency_header(:post, opts) do
    key = Keyword.get_lazy(opts, :idempotency_key, &generate_idempotency_key/0)
    [{"idempotency-key", key}]
  end

  defp idempotency_header(_method, _opts), do: []

  defp generate_idempotency_key do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end

  defp put_starting_after(params, last_id) do
    params
    |> Map.drop(["starting_after", "ending_before", :ending_before])
    |> Map.put(:starting_after, last_id)
  end

  defp retry_delay(n), do: Integer.pow(2, n) * 500

  @doc false
  def flatten_params(params) when is_map(params) do
    params
    |> Enum.flat_map(fn {k, v} -> flatten_key(to_string(k), v) end)
  end

  def flatten_params(params) when is_list(params), do: params

  # nil values are omitted; pass "" to unset a field in Stripe.
  defp flatten_key(_key, nil), do: []

  defp flatten_key(key, value) when is_map(value) do
    Enum.flat_map(value, fn {k, v} ->
      flatten_key("#{key}[#{k}]", v)
    end)
  end

  defp flatten_key(key, values) when is_list(values) do
    values
    |> Enum.with_index()
    |> Enum.flat_map(fn {v, i} -> flatten_key("#{key}[#{i}]", v) end)
  end

  defp flatten_key(key, value) when is_atom(value) do
    [{key, to_string(value)}]
  end

  defp flatten_key(key, value) do
    [{key, value}]
  end
end
