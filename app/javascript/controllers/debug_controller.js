import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.originalError = console.error
    this.originalWarn = console.warn

    console.error = (...args) => {
      this.log("error", args)
      this.originalError.apply(console, args)
    }

    console.warn = (...args) => {
      this.log("warn", args)
      this.originalWarn.apply(console, args)
    }

    window.onerror = (message, source, lineno, colno, error) => {
      this.log("error", [`Uncaught Error: ${message}`, { source, lineno, colno, error }])
    }

    window.onunhandledrejection = (event) => {
      this.log("error", [`Unhandled Rejection: ${event.reason}`])
    }
  }

  log(level, args) {
    const message = args.map(arg => {
      if (typeof arg === 'object') {
        try {
          return JSON.stringify(arg)
        } catch (e) {
          return String(arg)
        }
      }
      return String(arg)
    }).join(" ")

    fetch("/debug/log", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
      },
      body: JSON.stringify({
        level: level,
        message: message,
        url: window.location.href,
        timestamp: new Date().toISOString()
      })
    }).catch(err => {
      this.originalError.apply(console, ["Failed to send debug log", err])
    })
  }
}
