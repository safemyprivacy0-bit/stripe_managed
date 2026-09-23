defmodule StripeManaged.WebhookTest do
  use ExUnit.Case, async: true

  alias StripeManaged.{Webhook, TestHelpers}

  @secret "whsec_test_secret_key"

  test "construct_event/3 verifies valid signature and parses event" do
    payload = Jason.encode!(%{"type" => "checkout.session.completed", "id" => "evt_123"})
    signature = TestHelpers.sign_payload(payload, @secret)

    assert {:ok, event} = Webhook.construct_event(payload, signature, webhook_secret: @secret)
    assert event["type"] == "checkout.session.completed"
    assert event["id"] == "evt_123"
  end

  test "construct_event/3 rejects tampered payload" do
    payload = Jason.encode!(%{"type" => "checkout.session.completed"})
    signature = TestHelpers.sign_payload(payload, @secret)

    tampered = Jason.encode!(%{"type" => "charge.refunded"})

    assert {:error, "signature verification failed"} =
             Webhook.construct_event(tampered, signature, webhook_secret: @secret)
  end

  test "construct_event/3 rejects expired timestamp" do
    payload = Jason.encode!(%{"type" => "test"})
    old_timestamp = System.system_time(:second) - 600
    signature = TestHelpers.sign_payload(payload, @secret, old_timestamp)

    assert {:error, "timestamp outside tolerance" <> _} =
             Webhook.construct_event(payload, signature, webhook_secret: @secret)
  end

  test "construct_event/3 rejects missing signature" do
    payload = Jason.encode!(%{"type" => "test"})

    assert {:error, "missing stripe-signature header"} =
             Webhook.construct_event(payload, nil, webhook_secret: @secret)
  end

  test "construct_event/3 rejects wrong secret" do
    payload = Jason.encode!(%{"type" => "test"})
    signature = TestHelpers.sign_payload(payload, @secret)

    assert {:error, "signature verification failed"} =
             Webhook.construct_event(payload, signature, webhook_secret: "wrong_secret")
  end

  test "verify/3 returns :ok for valid signature" do
    payload = Jason.encode!(%{"type" => "test"})
    signature = TestHelpers.sign_payload(payload, @secret)

    assert :ok = Webhook.verify(payload, signature, webhook_secret: @secret)
  end

  test "verify/3 rejects invalid signature" do
    payload = Jason.encode!(%{"type" => "test"})
    signature = TestHelpers.sign_payload(payload, "wrong_secret")

    assert {:error, "signature verification failed"} =
             Webhook.verify(payload, signature, webhook_secret: @secret)
  end

  test "construct_event/3 rejects malformed signature header" do
    payload = Jason.encode!(%{"type" => "test"})

    assert {:error, "missing timestamp in signature"} =
             Webhook.construct_event(payload, "v1=abc123", webhook_secret: @secret)
  end

  test "construct_event/3 rejects signature without v1" do
    payload = Jason.encode!(%{"type" => "test"})

    assert {:error, "missing v1 signature"} =
             Webhook.construct_event(payload, "t=12345", webhook_secret: @secret)
  end

  test "construct_event/3 rejects non-numeric timestamp" do
    payload = Jason.encode!(%{"type" => "test"})

    assert {:error, "invalid timestamp"} =
             Webhook.construct_event(payload, "t=abc,v1=def", webhook_secret: @secret)
  end

  test "construct_event/3 rejects invalid JSON payload" do
    payload = "not json"
    signature = TestHelpers.sign_payload(payload, @secret)

    assert {:error, "invalid JSON payload"} =
             Webhook.construct_event(payload, signature, webhook_secret: @secret)
  end

  test "construct_event/3 with custom tolerance" do
    payload = Jason.encode!(%{"type" => "test"})
    old_timestamp = System.system_time(:second) - 10
    signature = TestHelpers.sign_payload(payload, @secret, old_timestamp)

    assert {:ok, _} =
             Webhook.construct_event(payload, signature, webhook_secret: @secret, tolerance: 60)
  end

  test "returns error instead of raising when no secret is configured" do
    payload = Jason.encode!(%{"type" => "test"})
    signature = TestHelpers.sign_payload(payload, @secret)

    assert {:error, "missing webhook secret"} = Webhook.construct_event(payload, signature)

    assert {:error, "missing webhook secret"} =
             Webhook.verify(payload, signature, webhook_secret: "")
  end

  test "reads the secret from application config" do
    payload = Jason.encode!(%{"type" => "test"})
    signature = TestHelpers.sign_payload(payload, @secret)

    Application.put_env(:stripe_managed, :webhook_secret, @secret)
    on_exit(fn -> Application.delete_env(:stripe_managed, :webhook_secret) end)

    assert {:ok, %{"type" => "test"}} = Webhook.construct_event(payload, signature)
  end

  test "rejects empty signature header" do
    assert {:error, "missing stripe-signature header"} =
             Webhook.verify("{}", "", webhook_secret: @secret)
  end

  test "rejects non-binary payload" do
    signature = TestHelpers.sign_payload("{}", @secret)

    assert {:error, "payload must be the raw request body string"} =
             Webhook.construct_event(%{"type" => "test"}, signature, webhook_secret: @secret)
  end

  test "accepts any matching v1 signature (secret rotation)" do
    payload = Jason.encode!(%{"type" => "test"})
    ts = System.system_time(:second)
    "t=" <> _ = valid = TestHelpers.sign_payload(payload, @secret, ts)
    "t=" <> _ = other = TestHelpers.sign_payload(payload, "old_secret", ts)
    [_, valid_sig] = String.split(valid, ",v1=")
    [_, other_sig] = String.split(other, ",v1=")

    header = "t=#{ts}, v1=#{other_sig}, v1=#{valid_sig}, v0=ignored"

    assert :ok = Webhook.verify(payload, header, webhook_secret: @secret)
  end

  test "rejects timestamp too far in the future" do
    payload = Jason.encode!(%{"type" => "test"})
    future = System.system_time(:second) + 600
    signature = TestHelpers.sign_payload(payload, @secret, future)

    assert {:error, "timestamp outside tolerance" <> _} =
             Webhook.verify(payload, signature, webhook_secret: @secret)
  end

  test "rejects signature of different length" do
    payload = Jason.encode!(%{"type" => "test"})
    ts = System.system_time(:second)

    assert {:error, "signature verification failed"} =
             Webhook.verify(payload, "t=#{ts},v1=abc", webhook_secret: @secret)
  end

  test "rejects valid JSON that is not an event object" do
    payload = "[1, 2, 3]"
    signature = TestHelpers.sign_payload(payload, @secret)

    assert {:error, "invalid JSON payload"} =
             Webhook.construct_event(payload, signature, webhook_secret: @secret)
  end
end
