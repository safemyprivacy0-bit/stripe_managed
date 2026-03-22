defmodule StripeManaged.TaxCodeTest do
  use ExUnit.Case, async: true

  alias StripeManaged.TaxCode

  test "all/0 returns map of tax codes" do
    codes = TaxCode.all()
    assert is_map(codes)
    assert map_size(codes) >= 30
  end

  test "eligible?/1 returns true for valid codes" do
    assert TaxCode.eligible?("txcd_10103001")
    assert TaxCode.eligible?("txcd_10103000")
  end

  test "eligible?/1 returns false for invalid codes" do
    refute TaxCode.eligible?("txcd_99999999")
    refute TaxCode.eligible?("invalid")
  end

  test "description/1 returns description for valid code" do
    assert TaxCode.description("txcd_10103001") == "SaaS - personal use"
  end

  test "description/1 returns nil for invalid code" do
    assert TaxCode.description("txcd_99999999") == nil
  end

  test "convenience functions return correct codes" do
    assert TaxCode.saas_personal() == "txcd_10103001"
    assert TaxCode.saas_business() == "txcd_10103000"
    assert TaxCode.software_personal() == "txcd_10101001"
    assert TaxCode.software_business() == "txcd_10101000"
    assert TaxCode.video_games_personal() == "txcd_10301001"
    assert TaxCode.ebooks_personal() == "txcd_10801001"
    assert TaxCode.online_courses_personal() == "txcd_10501001"
  end

  test "all convenience codes are eligible" do
    codes = [
      TaxCode.saas_personal(),
      TaxCode.saas_business(),
      TaxCode.software_personal(),
      TaxCode.software_business(),
      TaxCode.video_games_personal(),
      TaxCode.ebooks_personal(),
      TaxCode.online_courses_personal()
    ]

    Enum.each(codes, fn code ->
      assert TaxCode.eligible?(code), "Expected #{code} to be eligible"
      assert is_binary(TaxCode.description(code)), "Expected description for #{code}"
    end)
  end
end
