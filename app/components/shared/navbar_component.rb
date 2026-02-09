class Shared::NavbarComponent < ViewComponent::Base
  def initialize(project:, projects:, current_task: nil)
    @project = project
    @projects = projects || []
    @current_task = current_task
  end
end
