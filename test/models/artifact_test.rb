require "test_helper"

class ArtifactTest < ActiveSupport::TestCase
  test "valid artifact" do
    assert artifacts(:epic_one).valid?
  end

  test "requires title" do
    artifact = Artifact.new(project: projects(:agent_forge), artifact_type: "epic")
    assert_not artifact.valid?
    assert_includes artifact.errors[:title], "can't be blank"
  end

  test "requires artifact_type" do
    artifact = Artifact.new(project: projects(:agent_forge), title: "Test")
    assert_not artifact.valid?
  end

  test "parent-child relationship" do
    epic = artifacts(:epic_one)
    prd = artifacts(:prd_one)
    assert_equal epic, prd.parent
    assert_includes epic.children, prd
  end

  test "roots scope" do
    roots = Artifact.roots
    assert_includes roots, artifacts(:epic_one)
    assert_not_includes roots, artifacts(:prd_one)
  end

  test "by_type scope" do
    epics = Artifact.by_type("epic")
    assert_includes epics, artifacts(:epic_one)
    assert_not_includes epics, artifacts(:prd_one)
  end
end
