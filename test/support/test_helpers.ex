defmodule StripeManaged.TestHelpers do
  @moduledoc """
  Helpers for starting the mock server and building test config.
  """

  @doc """
  Starts the mock server on a random port and returns opts
  that point the client at localhost.
  """
  def start_mock_server do
    {:ok, _pid} = Plug.Cowboy.http(StripeManaged.MockServer, [], port: 0)
    port = get_port()

    [
      api_key: "sk_test_fake",
      base_url: "http://localhost:#{port}",
      api_version: "2025-03-31.basil"
    ]
  end

  @doc "Stops the mock server."
  def stop_mock_server do
    Plug.Cowboy.shutdown(StripeManaged.MockServer.HTTP)
  end

  defp get_port do
    info = :ranch.info(StripeManaged.MockServer.HTTP)
    # ranch 2.x returns a map
    case info do
      %{port: port} -> port
      info when is_list(info) -> Keyword.get(info, :port)
    end
  end

  @doc """
  Returns the test opts (api_key, base_url) stored in application env.
  Call this in test setup blocks.
  """
  def test_opts do
    Application.get_env(:stripe_managed, :test_opts)
  end

  @doc """
  Generates a valid webhook signature for testing.
  """
  def sign_payload(payload, secret, timestamp \\ nil) do
    ts = timestamp || System.system_time(:second)
    signed = "#{ts}.#{payload}"

    sig =
      :crypto.mac(:hmac, :sha256, secret, signed)
      |> Base.encode16(case: :lower)

    "t=#{ts},v1=#{sig}"
  end
end
