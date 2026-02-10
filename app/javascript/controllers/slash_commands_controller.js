import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "menu"]

  connect() {
    this.selectedIndex = -1
  }

  handleKeydown(event) {
    if (this.menuTarget.classList.contains("hidden")) {
      if (event.key === "/" && this.inputTarget.value === "") {
        this.showMenu()
      } else if (event.key === "Enter" && !event.shiftKey) {
        event.preventDefault()
        const form = this.inputTarget.form
        if (form) {
          console.log("[SlashCommands] Submitting form via Enter")
          if (typeof form.requestSubmit === 'function') {
            form.requestSubmit()
          } else {
            form.submit()
          }
        }
      }
      return
    }

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        this.moveSelection(1)
        break
      case "ArrowUp":
        event.preventDefault()
        this.moveSelection(-1)
        break
      case "Enter":
        if (this.selectedIndex >= 0) {
          event.preventDefault()
          this.selectOption(this.selectedIndex)
        }
        break
      case "Escape":
        this.hideMenu()
        break
    }
  }

  autoResize() {
    this.inputTarget.style.height = "auto"
    this.inputTarget.style.height = `${this.inputTarget.scrollHeight}px`
    
    if (this.inputTarget.value.startsWith("/")) {
      this.showMenu()
    } else {
      this.hideMenu()
    }
  }

  showMenu() {
    this.menuTarget.classList.remove("hidden")
  }

  hideMenu() {
    this.menuTarget.classList.add("hidden")
    this.selectedIndex = -1
    this.updateSelection()
  }

  moveSelection(delta) {
    const options = this.menuTarget.querySelectorAll("li a")
    this.selectedIndex = (this.selectedIndex + delta + options.length) % options.length
    this.updateSelection()
  }

  updateSelection() {
    const options = this.menuTarget.querySelectorAll("li a")
    options.forEach((opt, i) => {
      if (i === this.selectedIndex) {
        opt.classList.add("active")
        opt.scrollIntoView({ block: "nearest" })
      } else {
        opt.classList.remove("active")
      }
    })
  }

  select(event) {
    const command = event.currentTarget.dataset.command
    this.insertCommand(command)
  }

  selectOption(index) {
    const options = this.menuTarget.querySelectorAll("li a")
    const command = options[index].dataset.command
    this.insertCommand(command)
  }

  insertCommand(command) {
    this.inputTarget.value = command
    this.hideMenu()
    this.inputTarget.focus()
  }

  reset() {
    this.inputTarget.value = ""
    this.inputTarget.style.height = "auto"
    this.hideMenu()
  }
}
