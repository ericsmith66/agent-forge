require "test_helper"

class Chat::BubbleComponentTest < ViewComponent::TestCase
  def test_renders_user_message
    message = Message.new(role: "user", content: "Hello AI", created_at: Time.current)
    render_inline(Chat::BubbleComponent.new(message: message))
    
    assert_selector(".chat-end")
    assert_selector(".chat-bubble-primary", text: "Hello AI")
    assert_text("U")
  end

  def test_renders_assistant_message
    message = Message.new(role: "assistant", content: "Hello Human", created_at: Time.current)
    render_inline(Chat::BubbleComponent.new(message: message))
    
    assert_selector(".chat-start")
    assert_selector(".chat-bubble-secondary", text: "Hello Human")
    assert_text("A")
  end
end
