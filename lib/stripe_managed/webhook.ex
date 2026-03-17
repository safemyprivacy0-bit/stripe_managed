defmodule StripeManaged.Webhook do
  @moduledoc """
  Webhook signature verification and event construction.

  Stripe signs webhook payloads with HMAC-SHA256. Always verify
  signatures before processing events.

  ## Phoenix integration

      # In your endpoint.ex, add a raw body parser for the webhook route:
      plug Plug.Parsers,
        parsers: [:urlencoded, :multipart, :json],
        pass: ["*/*"],
        body_reader: {CacheBodyReader, :read_body, []},
        json_decoder: Jason

      # In your controller:
      def webhook(conn, _params) do
        payload = conn.assigns.raw_body
        signature = get_req_header(conn, "stripe-signature") |> List.first()

        case StripeManaged.Webhook.construct_event(payload, signature) do
          {:ok, event} -> handle_event(event)
          {:error, msg} -> send_resp(conn, 400, msg)
        end
      end
  """

  alias StripeManaged.Config

  @default_tolerance 300

  @doc """
  Verifies the webhook signature and parses the event payload.

  Returns `{:ok, event_map}` or `{:error, reason}`.

  Options:
    - `:webhook_secret` - override the configured secret
    - `:tolerance` - max age in seconds (default: 300)
  """
  @spec construct_event(String.t(), String.t(), keyword()) ::
          {:ok, map()} | {:error, String.t()}
  def construct_event(payload, signature, opts \\ []) do
    secret = Keyword.get(opts, :webhook_secret) || Config.webhook_secret(opts)
    tolerance = Keyword.get(opts, :tolerance, @default_tolerance)

    with {:ok, timestamp, signatures} <- parse_signature(signature),
         :ok <- verify_timestamp(timestamp, tolerance),
         :ok <- verify_signature(payload, timestamp, signatures, secret) do
      Jason.decode(payload)
      |> case do
        {:ok, event} -> {:ok, event}
        {:error, _} -> {:error, "invalid JSON payload"}
      end
    end
  end

  @doc """
  Verifies a webhook signature without parsing the payload.
  Returns `:ok` or `{:error, reason}`.
  """
  @spec verify(String.t(), String.t(), keyword()) :: :ok | {:error, String.t()}
  def verify(payload, signature, opts \\ []) do
    secret = Keyword.get(opts, :webhook_secret) || Config.webhook_secret(opts)
    tolerance = Keyword.get(opts, :tolerance, @default_tolerance)

    with {:ok, timestamp, signatures} <- parse_signature(signature),
         :ok <- verify_timestamp(timestamp, tolerance),
         :ok <- verify_signature(payload, timestamp, signatures, secret) do
      :ok
    end
  end

  # -- Private --

  defp parse_signature(nil), do: {:error, "missing stripe-signature header"}

  defp parse_signature(header) do
    parts =
      header
      |> String.split(",")
      |> Enum.map(&String.trim/1)
      |> Enum.map(fn part ->
        case String.split(part, "=", parts: 2) do
          [k, v] -> {k, v}
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    timestamp =
      parts
      |> Enum.find_value(fn {"t", v} -> v; _ -> nil end)

    signatures =
      parts
      |> Enum.filter(fn {"v1", _} -> true; _ -> false end)
      |> Enum.map(fn {_, v} -> v end)

    case {timestamp, signatures} do
      {nil, _} -> {:error, "missing timestamp in signature"}
      {_, []} -> {:error, "missing v1 signature"}
      {t, sigs} -> {:ok, t, sigs}
    end
  end

  defp verify_timestamp(timestamp_str, tolerance) do
    case Integer.parse(timestamp_str) do
      {timestamp, ""} ->
        now = System.system_time(:second)

        if abs(now - timestamp) <= tolerance do
          :ok
        else
          {:error, "timestamp outside tolerance (#{tolerance}s)"}
        end

      _ ->
        {:error, "invalid timestamp"}
    end
  end

  defp verify_signature(payload, timestamp, signatures, secret) do
    signed_payload = "#{timestamp}.#{payload}"

    expected =
      :crypto.mac(:hmac, :sha256, secret, signed_payload)
      |> Base.encode16(case: :lower)

    if Enum.any?(signatures, &secure_compare(&1, expected)) do
      :ok
    else
      {:error, "signature verification failed"}
    end
  end

  defp secure_compare(a, b) when byte_size(a) != byte_size(b), do: false

  defp secure_compare(a, b) do
    a_bytes = :binary.bin_to_list(a)
    b_bytes = :binary.bin_to_list(b)

    Enum.zip(a_bytes, b_bytes)
    |> Enum.reduce(0, fn {x, y}, acc -> Bitwise.bor(acc, Bitwise.bxor(x, y)) end)
    |> Kernel.==(0)
  end
end
