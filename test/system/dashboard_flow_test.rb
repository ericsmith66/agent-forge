require "application_system_test_case"

class DashboardFlowTest < ApplicationSystemTestCase
  setup do
    @project = Project.create!(name: "System Test Project", project_dir: "projects/system_test")
    @task = @project.tasks.create!(status: "pending")
    @artifact = @project.artifacts.create!(
      title: "Initial Artifact", 
      content: "Initial Content", 
      artifact_type: "prd", 
      status: "draft"
    )
  end

  test "navigating artifacts and editing" do
    visit dashboard_project_path(@project)

    assert_text "AGENT-FORGE"
    # Wait for artifacts to be rendered and grouped
    assert_text "PRDs", wait: 10
    assert_text "Initial Artifact"
    assert_text "Task: Main Thread"

    # Click artifact in tree
    find("a", text: "Initial Artifact").click

    # Verify viewer
    within "#artifact_viewer", wait: 10 do
      assert_text "Initial Artifact"
      assert_text "Initial Content"
      click_on "Edit"
    end

    # Edit artifact
    fill_in "artifact[title]", with: "Updated Title"
    fill_in "artifact[content]", with: "Updated Content"
    
    # Autosave should trigger, but we'll click Done to be sure
    click_on "Done"

    # Verify update in tree and viewer
    assert_text "Updated Title", wait: 10
    assert_text "Updated Content", wait: 10
    
    # Final check: Ensure we are back in viewer mode (Edit button exists)
    within "#artifact_viewer" do
      assert_selector "a[title='Edit']"
    end
  end

  test "sending a message in chat" do
    visit dashboard_project_path(@project)

    fill_in "message[content]", with: "Hello Junie"
    find("button[type='submit']").click

    assert_text "Hello Junie", wait: 10
    assert_selector ".chat-end", text: "Hello Junie"
    assert_text "Agent orchestration coming in Epic 4", wait: 10
  end
end
