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

    // Capture resource errors (404s on CSS/JS/Images)
    window.addEventListener('error', (event) => {
      if (event.target && (event.target.tagName === 'LINK' || event.target.tagName === 'SCRIPT' || event.target.tagName === 'IMG')) {
        this.log("error", [`Resource Load Failure: ${event.target.tagName} ${event.target.src || event.target.href}`])
      }
    }, true)

    // Capture Turbo lifecycle events
    document.addEventListener("turbo:frame-missing", (event) => {
      const { id, response, visit } = event.detail
      this.log("error", [`[TURBO] Frame missing: id="${id}"`, { url: visit?.location?.href || response?.url }])
    })

    document.addEventListener("turbo:error", (event) => {
      this.log("error", [`[TURBO] Request error`, { url: event.detail.url, status: event.detail.status }])
    })

    document.addEventListener("turbo:frame-load", (event) => {
      this.checkDOMHealth()
    })

    document.addEventListener("turbo:before-stream-render", (event) => {
      // Check for snapshot trigger in assistant replies
      const template = event.detail.newStream
      if (template.innerHTML.includes("DEBUG_COMMAND_TRIGGER:SNAPSHOT")) {
        this.snapshot()
      }
    })

    this.checkDOMHealth()
  }

  snapshot() {
    const panes = {
      sidebar: document.querySelector('aside')?.innerHTML?.substring(0, 1000),
      viewer: document.querySelector('#artifact_viewer')?.innerHTML?.substring(0, 1000),
      url: window.location.href
    }
    this.log("debug", [`[SNAPSHOT] UI State:`, panes])
  }

  checkDOMHealth() {
    // Detect Rails view annotations (<!-- BEGIN ...)
    const iterator = document.createNodeIterator(document.body, NodeFilter.SHOW_COMMENT)
    let node
    while (node = iterator.nextNode()) {
      if (node.nodeValue.includes("BEGIN app/views") || node.nodeValue.includes("END app/views")) {
        this.log("warn", [`[DOM] View annotations detected (leaking HTML comments). Ensure annotate_rendered_view_with_filenames is false.`])
        break
      }
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
        timestamp: new Date().toISOString(),
        userAgent: navigator.userAgent,
        viewport: `${window.innerWidth}x${window.innerHeight}`
      })
    }).catch(err => {
      this.originalError.apply(console, ["Failed to send debug log", err])
    })
  }
}
