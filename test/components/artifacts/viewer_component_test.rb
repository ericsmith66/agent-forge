require "test_helper"

class Artifacts::ViewerComponentTest < ViewComponent::TestCase
  def test_renders_artifact_content
    project = Project.create!(name: "Test Project", project_dir: "projects/test")
    artifact = Artifact.create!(project: project, title: "Test Artifact", content: "# Hello World", artifact_type: "prd", status: "draft")
    
    render_inline(Artifacts::ViewerComponent.new(artifact: artifact))
    
    assert_text("Test Artifact")
    assert_selector("h1", text: "Hello World")
    assert_selector(".badge", text: "draft")
  end

  def test_renders_empty_state
    project = Project.create!(name: "Empty Project", project_dir: "projects/empty")
    artifact = Artifact.create!(project: project, title: "Empty", content: "", artifact_type: "idea", status: "draft")
    
    render_inline(Artifacts::ViewerComponent.new(artifact: artifact))
    
    assert_text("This artifact has no content yet.")
  end
end
