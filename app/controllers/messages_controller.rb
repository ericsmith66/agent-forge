class MessagesController < ApplicationController
  before_action :set_task

  def create
    @message = @task.messages.new(message_params)
    @message.role = "user"

    if @message.save
      # Process slash commands or get AI response
      Coordinator.new(@task).process(@message)

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to project_dashboard_path(@task.project) }
      end
    else
      head :unprocessable_entity
    end
  end

  private

  def set_task
    @task = Task.find(params[:task_id])
  end

  def message_params
    params.require(:message).permit(:content)
  end
end
