defmodule StripeManaged.TaxCodeTest do
  use ExUnit.Case, async: true

  alias StripeManaged.TaxCode

  test "all/0 returns map of tax codes" do
    codes = TaxCode.all()
    assert is_map(codes)
    assert map_size(codes) == 76
  end

  test "eligible?/1 returns true for valid codes" do
    assert TaxCode.eligible?("txcd_10103001")
    assert TaxCode.eligible?("txcd_10103000")
    assert TaxCode.eligible?("txcd_10105001")
    assert TaxCode.eligible?("txcd_10105004")
    assert TaxCode.eligible?("txcd_37071001")
  end

  test "eligible?/1 returns false for invalid codes" do
    refute TaxCode.eligible?("txcd_99999999")
    refute TaxCode.eligible?("txcd_10101001")
    refute TaxCode.eligible?("invalid")
  end

  test "description/1 returns description for valid code" do
    assert TaxCode.description("txcd_10103000") ==
             "Software as a service (SaaS) - personal use"

    assert TaxCode.description("txcd_10103001") ==
             "Software as a service (SaaS) - business use"

    assert TaxCode.description("txcd_10105002") ==
             "Artificial Intelligence as a Service (AIaaS) - cloud based - business use"
  end

  test "description/1 returns nil for invalid code" do
    assert TaxCode.description("txcd_99999999") == nil
  end

  test "convenience functions return correct codes" do
    assert TaxCode.saas_personal() == "txcd_10103000"
    assert TaxCode.saas_business() == "txcd_10103001"
    assert TaxCode.software_personal() == "txcd_10202000"
    assert TaxCode.software_business() == "txcd_10202003"
    assert TaxCode.video_games_downloaded() == "txcd_10201000"
    assert TaxCode.digital_books_downloaded() == "txcd_10302000"
    assert TaxCode.online_courses_streamed() == "txcd_20060158"
    assert TaxCode.aiaas_cloud_personal() == "txcd_10105001"
    assert TaxCode.aiaas_cloud_business() == "txcd_10105002"
    assert TaxCode.aiaas_hybrid_personal() == "txcd_10105003"
    assert TaxCode.aiaas_hybrid_business() == "txcd_10105004"
  end

  test "legacy convenience functions point to current eligible categories" do
    assert TaxCode.video_games_personal() == TaxCode.video_games_downloaded()
    assert TaxCode.ebooks_personal() == TaxCode.digital_books_downloaded()
    assert TaxCode.online_courses_personal() == TaxCode.online_courses_streamed()
  end

  test "all convenience codes are eligible" do
    codes = [
      TaxCode.saas_personal(),
      TaxCode.saas_business(),
      TaxCode.software_personal(),
      TaxCode.software_business(),
      TaxCode.video_games_downloaded(),
      TaxCode.digital_books_downloaded(),
      TaxCode.online_courses_streamed(),
      TaxCode.aiaas_cloud_personal(),
      TaxCode.aiaas_cloud_business(),
      TaxCode.aiaas_hybrid_personal(),
      TaxCode.aiaas_hybrid_business()
    ]

    Enum.each(codes, fn code ->
      assert TaxCode.eligible?(code), "Expected #{code} to be eligible"
      assert is_binary(TaxCode.description(code)), "Expected description for #{code}"
    end)
  end
end
