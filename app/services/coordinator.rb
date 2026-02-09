class Coordinator
  def initialize(task)
    @task = task
    @project = task.project
  end

  def process(message)
    content = message.content.strip
    
    if content.start_with?("/")
      command, *args = content.split(" ")
      handle_command(command, args.join(" "))
    else
      reply("Agent orchestration coming in Epic 4. For now, use slash commands.")
    end
  end

  private

  def handle_command(command, args)
    case command
    when "/new-epic"
      artifact = @project.artifacts.create!(
        title: args.presence || "New Epic",
        artifact_type: "epic",
        status: "draft"
      )
      reply("Created Epic: #{artifact.title}")
    when "/prd"
      # Simple logic: attach to last created epic if none specified
      parent = @project.artifacts.epic.last
      artifact = @project.artifacts.create!(
        title: args.presence || "New PRD",
        artifact_type: "prd",
        status: "draft",
        parent: parent
      )
      reply("Created PRD: #{artifact.title} under #{parent&.title || 'no parent'}")
    when "/help"
      reply("Available commands: /new-epic <title>, /prd <title>, /status")
    when "/status"
      counts = @project.artifacts.group(:status).count
      reply("Project Status: #{counts.map { |k, v| "#{k}: #{v}" }.join(', ')}")
    else
      reply("Unknown command: #{command}. Type /help for available commands.")
    end
  end

  def reply(text)
    @task.messages.create!(role: "assistant", content: text)
  end
end
