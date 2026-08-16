require "test_helper"

class HeroiconHelperTest < ActionView::TestCase
  test "renders an outline icon by default" do
    svg = heroicon("check")

    assert_includes svg, "<svg"
    assert_equal svg, heroicon("check", variant: :outline)
    assert_not_equal svg, heroicon("check", variant: :solid)
  end

  test "outline is the configured default variant" do
    assert_equal :outline, Heroicon.configuration.variant
  end
end
