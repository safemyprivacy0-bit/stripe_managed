defmodule StripeManaged.Client do
  @moduledoc """
  HTTP client for the Stripe API.

  Handles authentication, request encoding, response parsing, and retries.
  All resource modules delegate to this module for actual HTTP calls.
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
  Lists resources with auto-pagination support.

  Returns a Stream that lazily fetches pages.
  """
  @spec list_paginated(String.t(), map(), keyword()) :: Enumerable.t()
  def list_paginated(path, params \\ %{}, opts \\ []) do
    Stream.resource(
      fn -> {path, params, opts} end,
      fn
        nil ->
          {:halt, nil}

        {path, params, opts} ->
          case get_with_query(path, params, opts) do
            {:ok, %{"data" => data, "has_more" => true}} ->
              last_id = data |> List.last() |> Map.get("id")
              next_params = Map.put(params, :starting_after, last_id)
              {data, {path, next_params, opts}}

            {:ok, %{"data" => data}} ->
              {data, nil}

            {:error, _} = error ->
              {[error], nil}
          end
      end,
      fn _ -> :ok end
    )
  end

  # -- Private --

  defp request(method, path, params, opts) do
    url = Config.base_url(opts) <> path

    req =
      Req.new(
        method: method,
        url: url,
        headers: headers(opts),
        retry: :transient,
        max_retries: 2,
        retry_delay: &retry_delay/1
      )

    req =
      if params && method in [:post] do
        Req.merge(req, form: flatten_params(params))
      else
        req
      end

    case Req.request(req) do
      {:ok, %Req.Response{status: status, body: body}} when status in 200..299 ->
        {:ok, body}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, Error.from_response(body, status)}

      {:error, reason} ->
        {:error, Error.network_error(reason)}
    end
  end

  defp get_with_query(path, params, opts) do
    query = params |> flatten_params() |> Enum.into([])

    url = Config.base_url(opts) <> path

    req =
      Req.new(
        method: :get,
        url: url,
        headers: headers(opts),
        params: query,
        retry: :transient,
        max_retries: 2,
        retry_delay: &retry_delay/1
      )

    case Req.request(req) do
      {:ok, %Req.Response{status: status, body: body}} when status in 200..299 ->
        {:ok, body}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, Error.from_response(body, status)}

      {:error, reason} ->
        {:error, Error.network_error(reason)}
    end
  end

  defp headers(opts) do
    [
      {"authorization", "Bearer #{Config.api_key(opts)}"},
      {"stripe-version", Config.api_version(opts)},
      {"content-type", "application/x-www-form-urlencoded"}
    ]
  end

  defp retry_delay(n), do: Integer.pow(2, n) * 500

  @doc false
  def flatten_params(params) when is_map(params) do
    params
    |> Enum.flat_map(fn {k, v} -> flatten_key(to_string(k), v) end)
  end

  def flatten_params(params) when is_list(params), do: params

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

  defp flatten_key(key, value) when is_boolean(value) do
    [{key, to_string(value)}]
  end

  defp flatten_key(key, value) when is_atom(value) do
    [{key, to_string(value)}]
  end

  defp flatten_key(key, value) do
    [{key, value}]
  end
end
