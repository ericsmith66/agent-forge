class ArtifactsController < ApplicationController
  before_action :set_project
  before_action :set_artifact, only: [:show, :edit, :update]

  def index
    @artifacts = @project.artifacts.roots.ordered
    render Artifacts::TreeComponent.new(project: @project)
  end

  def show
    if turbo_frame_request?
      render Artifacts::ViewerComponent.new(artifact: @artifact)
    else
      render Artifacts::TreeComponent.new(project: @project, current_artifact: @artifact)
    end
  end

  def edit
    render Artifacts::EditorComponent.new(artifact: @artifact)
  end

  def update
    if @artifact.update(artifact_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to project_artifact_path(@project, @artifact) }
      end
    else
      render Artifacts::EditorComponent.new(artifact: @artifact), status: :unprocessable_entity
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_artifact
    @artifact = @project.artifacts.find(params[:id])
  end

  def artifact_params
    params.require(:artifact).permit(:title, :content, :status)
  end
end
