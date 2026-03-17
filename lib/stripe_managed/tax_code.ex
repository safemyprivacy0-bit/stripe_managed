defmodule StripeManaged.TaxCode do
  @moduledoc """
  Eligible tax codes for Stripe Managed Payments.

  Only products with these tax codes can be sold through
  Managed Payments. These cover digital products: SaaS,
  software, games, digital media, online courses, etc.

  ## Usage

      # Get tax code for SaaS (personal use)
      StripeManaged.TaxCode.saas_personal()
      # => "txcd_10103001"

      # Check if a tax code is eligible
      StripeManaged.TaxCode.eligible?("txcd_10103001")
      # => true

      # List all eligible codes
      StripeManaged.TaxCode.all()
  """

  @codes %{
    # SaaS
    "txcd_10103001" => "SaaS - personal use",
    "txcd_10103000" => "SaaS - business use",

    # Software downloads
    "txcd_10101000" => "Software - business use",
    "txcd_10101001" => "Software - personal use",
    "txcd_10102000" => "Software - custom (business)",
    "txcd_10102001" => "Software - custom (personal)",

    # Digital content
    "txcd_10201000" => "Digital audio/visual works - business",
    "txcd_10201001" => "Digital audio/visual works - personal",
    "txcd_10202000" => "Digital audio works - business",
    "txcd_10202001" => "Digital audio works - personal",
    "txcd_10203000" => "Digital video works - business",
    "txcd_10203001" => "Digital video works - personal",

    # Video games
    "txcd_10301000" => "Video games - business",
    "txcd_10301001" => "Video games - personal",

    # Digital artwork
    "txcd_10401000" => "Digital artwork - business",
    "txcd_10401001" => "Digital artwork - personal",

    # Online courses / training
    "txcd_10501000" => "Online courses - business",
    "txcd_10501001" => "Online courses - personal",
    "txcd_10502000" => "Training services - business",
    "txcd_10502001" => "Training services - personal",

    # Digital advertising
    "txcd_10601000" => "Advertising services - business",
    "txcd_10601001" => "Advertising services - personal",

    # Information services
    "txcd_10701000" => "Information services - business",
    "txcd_10701001" => "Information services - personal",
    "txcd_10702000" => "Website information services - business",
    "txcd_10702001" => "Website information services - personal",

    # E-books / digital publications
    "txcd_10801000" => "E-books - business",
    "txcd_10801001" => "E-books - personal",
    "txcd_10802000" => "Digital newspapers/magazines - business",
    "txcd_10802001" => "Digital newspapers/magazines - personal"
  }

  @doc "Returns all eligible tax codes as a map of code => description."
  @spec all() :: map()
  def all, do: @codes

  @doc "Returns true if the given tax code is eligible for Managed Payments."
  @spec eligible?(String.t()) :: boolean()
  def eligible?(code), do: Map.has_key?(@codes, code)

  @doc "Returns the description for a tax code, or nil."
  @spec description(String.t()) :: String.t() | nil
  def description(code), do: Map.get(@codes, code)

  # Convenience functions for common codes
  def saas_personal, do: "txcd_10103001"
  def saas_business, do: "txcd_10103000"
  def software_personal, do: "txcd_10101001"
  def software_business, do: "txcd_10101000"
  def video_games_personal, do: "txcd_10301001"
  def ebooks_personal, do: "txcd_10801001"
  def online_courses_personal, do: "txcd_10501001"
end
