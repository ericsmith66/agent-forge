import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "status"]

  connect() {
    this.timeout = null
  }

  save() {
    this.statusTarget.textContent = "Saving..."
    
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.formTarget.requestSubmit()
    }, 1000)
  }

  // Called via turbo:submit-end (not currently set up in the HTML, but good for future)
  success() {
    this.statusTarget.textContent = "Saved"
  }
}
