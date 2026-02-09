class Artifacts::StatusBadgeComponent < ViewComponent::Base
  def initialize(status:)
    @status = status
  end

  def badge_class
    case @status.to_s
    when "draft"
      "badge-ghost"
    when "refined"
      "badge-info"
    when "approved"
      "badge-success"
    when "implemented"
      "badge-secondary"
    when "archived"
      "badge-outline"
    else
      "badge-ghost"
    end
  end
end
