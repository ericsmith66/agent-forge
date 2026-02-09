import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  close() {
    this.element.removeAttribute("open")
    // DaisyUI often uses focus to keep dropdown open. 
    // Blurring the active element helps.
    if (document.activeElement instanceof HTMLElement) {
      document.activeElement.blur()
    }
    
    // Sometimes dropdown remains visible if it was forced by a class.
    this.element.classList.remove("dropdown-open")
    
    // Explicitly hide the menu content if necessary
    const menu = this.element.querySelector(".dropdown-content")
    if (menu) {
      menu.style.display = "none"
      setTimeout(() => {
        menu.style.display = ""
      }, 100)
    }
  }
}
