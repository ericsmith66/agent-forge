# Create a default project for development
project = Project.find_or_create_by!(name: "Agent-Forge") do |p|
  p.description = "The Agent-Forge project itself"
  p.project_dir = "projects/agent-forge"
  p.active = true
end

# Create sample artifacts
if project.artifacts.empty?
  epic = Artifact.create!(
    project: project,
    artifact_type: "epic",
    title: "Epic 1 – Bootstrap & Infrastructure",
    status: "approved",
    position: 1
  )

  Artifact.create!(
    project: project,
    parent: epic,
    artifact_type: "prd",
    title: "PRD 1-01: Project Scaffold",
    status: "implemented",
    position: 1
  )

  Artifact.create!(
    project: project,
    parent: epic,
    artifact_type: "prd",
    title: "PRD 1-02: Database Schema",
    status: "implemented",
    position: 2
  )

  epic2 = Artifact.create!(
    project: project,
    artifact_type: "epic",
    title: "Epic 2 – UI Foundation",
    status: "draft",
    position: 2
  )

  Artifact.create!(
    project: project,
    parent: epic2,
    artifact_type: "prd",
    title: "PRD 2-01: Rails Scaffold",
    status: "draft",
    position: 1
  )
end

puts "Seeded #{Project.count} project(s), #{Artifact.count} artifact(s)"
