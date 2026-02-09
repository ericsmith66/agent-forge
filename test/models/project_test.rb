require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  test "valid project" do
    project = projects(:agent_forge)
    assert project.valid?
  end

  test "requires name" do
    project = Project.new(project_dir: "projects/test")
    assert_not project.valid?
    assert_includes project.errors[:name], "can't be blank"
  end

  test "requires unique name" do
    project = Project.new(name: "Agent-Forge", project_dir: "projects/dupe")
    assert_not project.valid?
    assert_includes project.errors[:name], "has already been taken"
  end

  test "requires project_dir" do
    project = Project.new(name: "Test")
    assert_not project.valid?
    assert_includes project.errors[:project_dir], "can't be blank"
  end

  test "project_dir must be under projects/" do
    project = Project.new(name: "Bad", project_dir: "/tmp/bad")
    assert_not project.valid?
    assert_includes project.errors[:project_dir], "must be under projects/"
  end

  test "active scope" do
    assert_includes Project.active, projects(:agent_forge)
    assert_not_includes Project.active, projects(:inactive_project)
  end

  test "has many artifacts" do
    project = projects(:agent_forge)
    assert_respond_to project, :artifacts
    assert project.artifacts.count > 0
  end

  test "has many tasks" do
    project = projects(:agent_forge)
    assert_respond_to project, :tasks
  end

  test "destroys dependent artifacts" do
    project = projects(:agent_forge)
    assert_difference "Artifact.count", -project.artifacts.count do
      project.destroy
    end
  end
end
