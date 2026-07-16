defmodule StripeManaged.TaxCode do
  @moduledoc """
  Eligible product tax codes for Stripe Managed Payments.

  The catalog is a snapshot of Stripe's official
  [Managed Payments eligibility documentation](https://docs.stripe.com/payments/managed-payments/eligibility)
  verified on July 16, 2026. Stripe can change eligibility independently of
  this library, so check the official documentation or Dashboard before
  creating production Products.

  ## Usage

      # Get the tax code for SaaS sold for personal use
      StripeManaged.TaxCode.saas_personal()
      # => "txcd_10103000"

      # Check whether a code is in the verified catalog
      StripeManaged.TaxCode.eligible?("txcd_10103000")
      # => true

      # List the complete verified catalog
      StripeManaged.TaxCode.all()
  """

  @codes %{
    # General and cloud services
    "txcd_10000000" => "General - Electronically Supplied Services",
    "txcd_10010001" => "Infrastructure as a service (IaaS) - personal use",
    "txcd_10101000" => "Infrastructure as a service (IaaS) - business use",
    "txcd_10102000" => "Platform as a service (PaaS) - business use",
    "txcd_10102001" => "Platform as a service (PaaS) - personal use",
    "txcd_10103000" => "Software as a service (SaaS) - personal use",
    "txcd_10103001" => "Software as a service (SaaS) - business use",
    "txcd_10103100" => "Software as a service (SaaS) - electronic download - personal use",
    "txcd_10103101" => "Software as a service (SaaS) - electronic download - business use",
    "txcd_10105001" =>
      "Artificial Intelligence as a Service (AIaaS) - cloud based - personal use",
    "txcd_10105002" =>
      "Artificial Intelligence as a Service (AIaaS) - cloud based - business use",
    "txcd_10105003" =>
      "Artificial Intelligence as a Service (AIaaS) - cloud based and downloaded - personal use",
    "txcd_10105004" =>
      "Artificial Intelligence as a Service (AIaaS) - cloud based and downloaded - business use",

    # Video games and downloadable software
    "txcd_10201000" => "Video games - downloaded - non-subscription - permanent rights",
    "txcd_10201001" => "Video games - downloaded - non-subscription - limited rights",
    "txcd_10201002" => "Video games - downloaded - subscription - conditional rights",
    "txcd_10201003" => "Video games - streamed - non-subscription - limited rights",
    "txcd_10201004" => "Video games - streamed - subscription - conditional rights",
    "txcd_10202000" => "Downloadable software - personal use",
    "txcd_10202001" => "Downloadable software - non-recreational - personal use",
    "txcd_10202003" => "Downloadable software - business use",

    # Digital books, magazines, newspapers, and textbooks
    "txcd_10301000" => "Audiobook",
    "txcd_10302000" => "Digital books - downloaded - non-subscription - permanent rights",
    "txcd_10302001" => "Digital books - downloaded - non-subscription - limited rights",
    "txcd_10302002" => "Digital books - downloaded - subscription - conditional rights",
    "txcd_10302003" => "Digital books - viewable only - subscription - conditional rights",
    "txcd_10303000" =>
      "Digital magazines and periodicals - downloadable - subscription - conditional rights",
    "txcd_10303002" =>
      "Digital magazines and periodicals - viewable only - subscription - conditional rights",
    "txcd_10303100" =>
      "Digital magazines and periodicals - downloadable - non-subscription - permanent rights",
    "txcd_10303101" =>
      "Digital magazines and periodicals - viewable only - non-subscription - limited rights",
    "txcd_10303102" =>
      "Digital magazines and periodicals - viewable only - non-subscription - permanent rights",
    "txcd_10303104" =>
      "Digital magazines and periodicals - downloadable - non-subscription - limited rights",
    "txcd_10304000" => "Digital newspapers - downloadable - non-subscription - permanent rights",
    "txcd_10304001" => "Digital newspapers - viewable only - non-subscription - limited rights",
    "txcd_10304002" => "Digital newspapers - viewable only - non-subscription - permanent rights",
    "txcd_10304003" => "Digital newspapers - downloadable - non-subscription - limited rights",
    "txcd_10304100" => "Digital newspapers - downloadable - subscription - conditional rights",
    "txcd_10304102" => "Digital newspapers - viewable only - subscription - conditional rights",
    "txcd_10305000" =>
      "Digital school textbooks - downloaded - non-subscription - limited rights",
    "txcd_10305001" =>
      "Digital school textbooks - downloaded - non-subscription - permanent rights",

    # Digital audio and audiovisual works
    "txcd_10401000" => "Digital audio works - streamed - non-subscription - limited rights",
    "txcd_10401001" => "Digital audio works - downloaded - non-subscription - limited rights",
    "txcd_10401100" => "Digital audio works - downloaded - non-subscription - permanent rights",
    "txcd_10401200" => "Digital audio works - streamed - subscription - conditional rights",
    "txcd_10402000" => "Digital audiovisual works - streamed - non-subscription - limited rights",
    "txcd_10402100" =>
      "Digital audiovisual works - downloaded - non-subscription - permanent rights",
    "txcd_10402110" =>
      "Digital audiovisual works - downloaded - non-subscription - limited rights",
    "txcd_10402200" => "Digital audiovisual works - streamed - subscription - conditional rights",

    # Digital images, documents, artwork, and greeting cards
    "txcd_10501000" => "Digital photographs and images - downloaded - permanent rights",
    "txcd_10503000" =>
      "Digital news or documents - downloadable - non-subscription - permanent rights",
    "txcd_10503001" =>
      "Digital news or documents - downloadable - non-subscription - limited rights",
    "txcd_10503002" =>
      "Digital news or documents - downloadable - subscription - conditional rights",
    "txcd_10503003" =>
      "Digital news or documents - viewable only - non-subscription - limited rights",
    "txcd_10503004" =>
      "Digital news or documents - viewable only - non-subscription - permanent rights",
    "txcd_10503005" =>
      "Digital news or documents - viewable only - subscription - conditional rights",
    "txcd_10504003" =>
      "Electronic software documentation or user manuals - prewritten - electronic delivery",
    "txcd_10505000" =>
      "Digital finished artwork - downloaded - non-subscription - limited rights",
    "txcd_10505001" =>
      "Digital finished artwork - downloaded - non-subscription - permanent rights",
    "txcd_10505002" =>
      "Digital finished artwork - downloaded - subscription - conditional rights",
    "txcd_10506000" => "Digital greeting cards - audio only",
    "txcd_10506001" => "Digital greeting cards - audiovisual",
    "txcd_10506002" => "Digital greeting cards - static text or images only",

    # Website and information services
    "txcd_10701100" => "Website hosting",
    "txcd_10701400" => "Website information services - business use",
    "txcd_10701401" => "Website information services - personal use",
    "txcd_10701410" => "Electronically delivered information services - business use",
    "txcd_10701411" => "Electronically delivered information services - personal use",

    # Bundled digital media
    "txcd_10804001" =>
      "Digital audiovisual works bundle - downloaded and streamed - subscription",
    "txcd_10804002" =>
      "Digital audiovisual works bundle - limited download and streamed - non-subscription",
    "txcd_10804003" =>
      "Digital audiovisual works bundle - permanent download and streamed - non-subscription",
    "txcd_10804010" => "Digital audio works bundle - downloaded and streamed - subscription",

    # Online courses and training
    "txcd_20060058" => "Training services - self-study web-based",
    "txcd_20060158" => "On-demand online courses - streamed audio or audiovisual content",
    "txcd_20060258" =>
      "On-demand online courses - streamed and downloadable audio or audiovisual content",
    "txcd_20060358" => "On-demand online courses - written material",

    # Software maintenance
    "txcd_37071001" =>
      "Software maintenance agreement - optional - prewritten - electronic updates"
  }

  @doc "Returns the verified map of eligible tax code to Stripe category name."
  @spec all() :: %{String.t() => String.t()}
  def all, do: @codes

  @doc "Returns true when the code is present in the verified Managed Payments catalog."
  @spec eligible?(String.t()) :: boolean()
  def eligible?(code), do: Map.has_key?(@codes, code)

  @doc "Returns the Stripe category name for a code, or nil when it isn't in the catalog."
  @spec description(String.t()) :: String.t() | nil
  def description(code), do: Map.get(@codes, code)

  @doc "SaaS delivered online for personal use."
  @spec saas_personal() :: String.t()
  def saas_personal, do: "txcd_10103000"

  @doc "SaaS delivered online for business use."
  @spec saas_business() :: String.t()
  def saas_business, do: "txcd_10103001"

  @doc "Downloadable prewritten software for personal use."
  @spec software_personal() :: String.t()
  def software_personal, do: "txcd_10202000"

  @doc "Downloadable prewritten software for business use."
  @spec software_business() :: String.t()
  def software_business, do: "txcd_10202003"

  @doc "A downloaded video game sold with permanent rights."
  @spec video_games_downloaded() :: String.t()
  def video_games_downloaded, do: "txcd_10201000"

  @doc "A downloaded digital book sold with permanent rights."
  @spec digital_books_downloaded() :: String.t()
  def digital_books_downloaded, do: "txcd_10302000"

  @doc "An on-demand course with streamed audio or audiovisual content."
  @spec online_courses_streamed() :: String.t()
  def online_courses_streamed, do: "txcd_20060158"

  @doc "Cloud-based AI as a service for personal use."
  @spec aiaas_cloud_personal() :: String.t()
  def aiaas_cloud_personal, do: "txcd_10105001"

  @doc "Cloud-based AI as a service for business use."
  @spec aiaas_cloud_business() :: String.t()
  def aiaas_cloud_business, do: "txcd_10105002"

  @doc "Hybrid cloud and downloaded AI as a service for personal use."
  @spec aiaas_hybrid_personal() :: String.t()
  def aiaas_hybrid_personal, do: "txcd_10105003"

  @doc "Hybrid cloud and downloaded AI as a service for business use."
  @spec aiaas_hybrid_business() :: String.t()
  def aiaas_hybrid_business, do: "txcd_10105004"

  @doc "Backward-compatible alias for `video_games_downloaded/0`."
  @spec video_games_personal() :: String.t()
  def video_games_personal, do: video_games_downloaded()

  @doc "Backward-compatible alias for `digital_books_downloaded/0`."
  @spec ebooks_personal() :: String.t()
  def ebooks_personal, do: digital_books_downloaded()

  @doc "Backward-compatible alias for `online_courses_streamed/0`."
  @spec online_courses_personal() :: String.t()
  def online_courses_personal, do: online_courses_streamed()
end
