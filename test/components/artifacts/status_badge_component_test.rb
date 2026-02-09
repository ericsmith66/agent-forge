require "test_helper"

class Artifacts::StatusBadgeComponentTest < ViewComponent::TestCase
  def test_renders_draft_status
    render_inline(Artifacts::StatusBadgeComponent.new(status: "draft"))
    assert_selector(".badge-ghost", text: "draft")
  end

  def test_renders_refined_status
    render_inline(Artifacts::StatusBadgeComponent.new(status: "refined"))
    assert_selector(".badge-info", text: "refined")
  end

  def test_renders_approved_status
    render_inline(Artifacts::StatusBadgeComponent.new(status: "approved"))
    assert_selector(".badge-success", text: "approved")
  end
end
