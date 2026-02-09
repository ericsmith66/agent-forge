require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "GET root shows dashboard" do
    get root_path
    assert_response :success
    assert_select "header", text: /AGENT-FORGE/
  end

  test "shows first active project by default" do
    get root_path
    assert_response :success
    assert_select "#project-switcher-dropdown", text: /Agent-Forge/
  end

  test "shows specific project via project_id" do
    project = projects(:agent_forge)
    get dashboard_project_path(project)
    assert_response :success
    assert_select "#project-switcher-dropdown", text: /Agent-Forge/
  end

  test "redirects for invalid project_id" do
    get dashboard_project_path(id: 999999)
    assert_redirected_to root_path
    assert_equal "Project not found", flash[:alert]
  end

  test "shows project switcher when projects exist" do
    get root_path
    assert_response :success
    assert_select "#project-switcher-dropdown"
  end

  test "shows active status in navbar" do
    get root_path
    assert_response :success
    assert_select ".badge-success", text: /Active/
  end

  test "shows artifact tree" do
    get root_path
    assert_response :success
    assert_select "#artifact_tree"
  end
end
