class Chat::BubbleComponent < ViewComponent::Base
  def initialize(message:)
    @message = message
  end

  def alignment_class
    @message.role == "user" ? "chat-end" : "chat-start"
  end

  def bubble_class
    case @message.role
    when "user"
      "chat-bubble-primary text-primary-content"
    when "assistant"
      "bg-base-200 text-base-content border border-base-300"
    when "system"
      "badge badge-ghost badge-sm gap-2 py-3 px-4 italic opacity-70"
    when "tool"
      "badge badge-ghost badge-sm gap-2 py-3 px-4 italic opacity-70"
    else
      ""
    end
  end

  def avatar_text
    @message.role == "user" ? "U" : "J"
  end
end
