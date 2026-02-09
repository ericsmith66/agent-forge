import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.highlightCurrent()
    document.addEventListener("turbo:frame-load", this.highlightCurrent.bind(this))
  }

  disconnect() {
    document.removeEventListener("turbo:frame-load", this.highlightCurrent.bind(this))
  }

  highlightCurrent(event) {
    let currentPath = window.location.pathname
    
    // If triggered by frame load, we might want to check the URL of the frame if it changed
    // but usually the main URL doesn't change on frame navigation.
    // However, for highlighting we need to know which artifact is active.
    
    const links = this.element.querySelectorAll("a[data-turbo-frame='artifact_viewer']")
    
    links.forEach(link => {
      const href = link.getAttribute("href")
      if (href === currentPath || (event?.detail?.fetchResponse?.response?.url?.includes(href))) {
        link.classList.add("bg-primary", "text-primary-content", "shadow")
        link.classList.remove("text-base-content", "hover:bg-base-300")
        
        // Ensure parent details are open
        let parentDetails = link.closest("details")
        while (parentDetails) {
          parentDetails.open = true
          parentDetails = parentDetails.parentElement.closest("details")
        }
      } else {
        link.classList.remove("bg-primary", "text-primary-content", "shadow")
        link.classList.add("text-base-content", "hover:bg-base-300")
      }
    })
  }
}
