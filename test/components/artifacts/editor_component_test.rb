require "test_helper"

class Artifacts::EditorComponentTest < ViewComponent::TestCase
  def test_renders_editor_with_artifact_data
    project = Project.create!(name: "Editor Project", project_dir: "projects/editor")
    artifact = Artifact.create!(project: project, title: "Editable", content: "Original content", artifact_type: "prd", status: "draft")
    
    render_inline(Artifacts::EditorComponent.new(artifact: artifact))
    
    assert_selector("input[value='Editable']")
    assert_selector("textarea", text: "Original content")
    assert_text("Saved")
  end
end
