class Artifacts::TreeItemComponent < ViewComponent::Base
  def initialize(artifact:, selected: false, depth: 0)
    @artifact = artifact
    @selected = selected
    @depth = depth
  end

  def icon_class
    case @artifact.artifact_type
    when "idea"
      "lightbulb"
    when "epic"
      "layers"
    when "prd"
      "file-text"
    when "backlog_item"
      "clipboard-list"
    else
      "file"
    end
  end

  def indentation_class
    @depth > 0 ? "" : ""
  end
end
