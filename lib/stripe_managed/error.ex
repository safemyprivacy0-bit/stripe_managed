defmodule StripeManaged.Error do
  @moduledoc """
  Structured error returned by all API calls.

  ## Fields

    * `:type` - error category (`:api_error`, `:card_error`, `:invalid_request`,
      `:authentication`, `:rate_limit`, `:network`)
    * `:code` - Stripe error code string (e.g. `"resource_missing"`)
    * `:message` - human-readable description
    * `:param` - the parameter that caused the error (if applicable)
    * `:status` - HTTP status code
  """

  @type t :: %__MODULE__{
          type: atom(),
          code: String.t() | nil,
          message: String.t(),
          param: String.t() | nil,
          status: integer() | nil
        }

  defstruct [:type, :code, :message, :param, :status]

  @doc false
  def from_response(%{"error" => error}, status) do
    %__MODULE__{
      type: parse_type(error["type"]),
      code: error["code"],
      message: error["message"] || "Unknown error",
      param: error["param"],
      status: status
    }
  end

  def from_response(_body, status) do
    %__MODULE__{
      type: :api_error,
      message: "Unexpected response (HTTP #{status})",
      status: status
    }
  end

  @doc false
  def network_error(reason) do
    %__MODULE__{
      type: :network,
      message: "Network error: #{inspect(reason)}"
    }
  end

  defp parse_type("api_error"), do: :api_error
  defp parse_type("card_error"), do: :card_error
  defp parse_type("idempotency_error"), do: :idempotency_error
  defp parse_type("invalid_request_error"), do: :invalid_request
  defp parse_type("authentication_error"), do: :authentication
  defp parse_type("rate_limit_error"), do: :rate_limit
  defp parse_type(_), do: :api_error
end
