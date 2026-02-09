require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "GET root shows dashboard" do
    get root_path
    assert_response :success
    assert_select "[data-testid='navbar']"
    assert_select "[data-testid='dashboard-content']"
  end

  test "shows first active project by default" do
    get root_path
    assert_response :success
    assert_select "[data-testid='current-project-name']", text: /Agent-Forge/
  end

  test "shows specific project via project_id" do
    project = projects(:agent_forge)
    get dashboard_project_path(project)
    assert_response :success
    assert_select "[data-testid='current-project-name']", text: /Agent-Forge/
  end

  test "redirects for invalid project_id" do
    get dashboard_project_path(id: 999999)
    assert_redirected_to root_path
    assert_equal "Project not found", flash[:alert]
  end

  test "shows project switcher when projects exist" do
    get root_path
    assert_response :success
    assert_select "[data-testid='project-switcher']"
  end

  test "shows welcome message when no projects" do
    Project.destroy_all
    get root_path
    assert_response :success
    assert_select "h2", text: "Welcome to Agent-Forge"
  end

  test "shows artifact stats" do
    get root_path
    assert_response :success
    assert_select "[data-testid='stat-artifacts']"
    assert_select "[data-testid='stat-tasks']"
    assert_select "[data-testid='stat-status']"
  end

  test "shows artifacts table" do
    get root_path
    assert_response :success
    # epic_one is a root artifact
    assert_select "table.table"
    assert_select "td", text: /Epic 1/
  end
end
