import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages"]

  connect() {
    this.scrollToBottom()
    this.setupMutationObserver()
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  scrollToBottom() {
    const container = this.messagesTarget
    container.scrollTop = container.scrollHeight
  }

  setupMutationObserver() {
    this.observer = new MutationObserver(() => {
      this.scrollToBottom()
    })

    this.observer.observe(this.messagesTarget, {
      childList: true,
      subtree: true
    })
  }

  // Handle manual force scroll if needed
  forceScrollToBottom() {
    this.scrollToBottom()
  }
}
