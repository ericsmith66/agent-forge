class Artifacts::TreeComponent < ViewComponent::Base
  delegate :turbo_frame_tag, to: :helpers
  def initialize(project:, current_artifact: nil)
    @project = project
    @current_artifact = current_artifact
  end

  def artifact_groups
    {
      "Epics" => @project.artifacts.epic.roots.ordered,
      "Ideas" => @project.artifacts.idea.roots.ordered,
      "Backlog" => @project.artifacts.backlog_item.roots.ordered,
      "PRDs" => @project.artifacts.prd.roots.ordered
    }
  end
end
