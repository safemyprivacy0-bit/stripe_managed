defmodule StripeManaged.ErrorTest do
  use ExUnit.Case, async: true

  alias StripeManaged.Error

  describe "from_response/2" do
    test "parses standard API error" do
      body = %{
        "error" => %{
          "type" => "invalid_request_error",
          "code" => "resource_missing",
          "message" => "No such product",
          "param" => "id"
        }
      }

      error = Error.from_response(body, 404)
      assert error.type == :invalid_request
      assert error.code == "resource_missing"
      assert error.message == "No such product"
      assert error.param == "id"
      assert error.status == 404
    end

    test "parses authentication error" do
      body = %{"error" => %{"type" => "authentication_error", "message" => "Invalid API key"}}
      error = Error.from_response(body, 401)
      assert error.type == :authentication
      assert error.message == "Invalid API key"
    end

    test "parses card error" do
      body = %{"error" => %{"type" => "card_error", "code" => "card_declined", "message" => "Declined"}}
      error = Error.from_response(body, 402)
      assert error.type == :card_error
      assert error.code == "card_declined"
    end

    test "parses rate limit error" do
      body = %{"error" => %{"type" => "rate_limit_error", "message" => "Too many requests"}}
      error = Error.from_response(body, 429)
      assert error.type == :rate_limit
    end

    test "parses idempotency error" do
      body = %{"error" => %{"type" => "idempotency_error", "message" => "Keys must be unique"}}
      error = Error.from_response(body, 400)
      assert error.type == :idempotency_error
    end

    test "parses api_error type" do
      body = %{"error" => %{"type" => "api_error", "message" => "Internal error"}}
      error = Error.from_response(body, 500)
      assert error.type == :api_error
    end

    test "defaults unknown type to api_error" do
      body = %{"error" => %{"type" => "some_future_type", "message" => "Something"}}
      error = Error.from_response(body, 400)
      assert error.type == :api_error
    end

    test "handles missing message" do
      body = %{"error" => %{"type" => "api_error"}}
      error = Error.from_response(body, 500)
      assert error.message == "Unknown error"
    end

    test "handles unexpected body format" do
      error = Error.from_response(%{"something" => "else"}, 502)
      assert error.type == :api_error
      assert error.message == "Unexpected response (HTTP 502)"
      assert error.status == 502
    end

    test "handles nil body" do
      error = Error.from_response(nil, 500)
      assert error.type == :api_error
      assert error.status == 500
    end
  end

  describe "network_error/1" do
    test "wraps reason in network error" do
      error = Error.network_error(:timeout)
      assert error.type == :network
      assert error.message =~ "timeout"
      assert error.status == nil
    end

    test "wraps complex reason" do
      error = Error.network_error({:tls_alert, :handshake_failure})
      assert error.type == :network
      assert error.message =~ "tls_alert"
    end
  end
end
