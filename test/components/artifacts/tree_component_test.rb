require "test_helper"

class Artifacts::TreeComponentTest < ViewComponent::TestCase
  def test_renders_artifact_tree
    project = Project.create!(name: "Tree Project", project_dir: "projects/tree")
    Artifact.create!(project: project, title: "Idea 1", artifact_type: "idea", status: "draft")
    Artifact.create!(project: project, title: "Epic 1", artifact_type: "epic", status: "draft")
    
    render_inline(Artifacts::TreeComponent.new(project: project))
    
    assert_text("Idea 1")
    assert_text("Epic 1")
    assert_text("Ideas (1)")
    assert_text("Epics (1)")
  end

  def test_renders_empty_tree
    project = Project.create!(name: "Empty Tree", project_dir: "projects/empty_tree")
    
    render_inline(Artifacts::TreeComponent.new(project: project))
    
    assert_text("No artifacts yet")
  end
end
