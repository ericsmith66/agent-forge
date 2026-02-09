class DashboardController < ApplicationController
  def show
    @project = find_project

    if params[:id] && @project.nil?
      redirect_to root_path, alert: "Project not found"
      return
    end

    @projects = Project.active.order(:name)
    @artifacts = @project&.artifacts&.roots&.ordered || []
    @current_task = @project&.tasks&.last
  end

  private

  def find_project
    if params[:id]
      Project.find_by(id: params[:id])
    else
      Project.active.order(:name).first
    end
  end
end
