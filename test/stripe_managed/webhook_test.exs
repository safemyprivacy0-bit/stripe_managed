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
end
