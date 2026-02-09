# Epic 002: JavaScript Architecture & Implementation Guide

**Epic ID:** 002-UI-Foundation
**Document:** JavaScript Architecture
**Created:** 2026-02-08
**Last Updated:** 2026-02-08

---

## Table of Contents

1. [Philosophy & Principles](#philosophy--principles)
2. [Stimulus Framework Architecture](#stimulus-framework-architecture)
3. [Controller Reference Guide](#controller-reference-guide)
4. [ActionCable Integration](#actioncable-integration)
5. [Utility Functions & Helpers](#utility-functions--helpers)
6. [Testing Strategy](#testing-strategy)
7. [Performance Optimization](#performance-optimization)
8. [Debugging & Development](#debugging--development)

---

## Philosophy & Principles

### The Stimulus Way

Stimulus follows the **progressive enhancement** philosophy:

1. **HTML First**: Structure comes from server-rendered HTML (ViewComponents)
2. **Behavior Second**: JavaScript adds interactivity, not structure
3. **No State Management**: State lives in DOM and server (not in JS objects)
4. **Controllers are Ephemeral**: Connected/disconnected as DOM changes

### Core Principles for agent-forge

**1. Server Authority**
- Rails renders HTML with data
- JavaScript enhances behavior (auto-scroll, keyboard nav, autosave)
- Turbo handles navigation and updates
- Never duplicate logic between client and server

**2. Minimal JavaScript**
- Use Stimulus controllers only for behavior that requires JS
- Prefer Turbo Frames/Streams for updates (not fetch/AJAX)
- Keep controllers small (<150 lines)
- Delegate complex logic to server

**3. Progressive Enhancement**
- All features work without JavaScript (graceful degradation)
- Enhance with JS for better UX
- Examples:
  - Form submission works via standard POST (JS adds autosave)
  - Links work via Turbo Frame (JS adds keyboard shortcuts)
  - Chat works with page reloads (JS adds streaming)

**4. Zero Build Step (Rails 8 Import Maps)**
- No webpack, no npm install in production
- Import maps for modern ES6 modules
- Stimulus controllers auto-loaded via `import { Application } from "@hotwired/stimulus"`

---

## Stimulus Framework Architecture

### Application Setup

```javascript
// app/javascript/application.js
import "@hotwired/turbo-rails"
import "./controllers"
import "./channels"
```

```javascript
// app/javascript/controllers/application.js
import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

export { application }
```

```javascript
// app/javascript/controllers/index.js
import { application } from "./application"

// Auto-register all controllers
import ChatScrollController from "./chat_scroll_controller"
import TreeNavigationController from "./tree_navigation_controller"
import AutosaveController from "./autosave_controller"
import ModalController from "./modal_controller"
import CommandPaletteController from "./command_palette_controller"
import DiffViewerController from "./diff_viewer_controller"
import SlashCommandsController from "./slash_commands_controller"
import ProjectSwitcherController from "./project_switcher_controller"
import ToastController from "./toast_controller"

application.register("chat-scroll", ChatScrollController)
application.register("tree-navigation", TreeNavigationController)
application.register("autosave", AutosaveController)
application.register("modal", ModalController)
application.register("command-palette", CommandPaletteController)
application.register("diff-viewer", DiffViewerController)
application.register("slash-commands", SlashCommandsController)
application.register("project-switcher", ProjectSwitcherController)
application.register("toast", ToastController)
```

### Controller Lifecycle

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // Called when controller connects to DOM
  connect() {
    console.log("Controller connected:", this.element)
    this.setupEventListeners()
  }

  // Called when controller disconnects from DOM
  disconnect() {
    console.log("Controller disconnected:", this.element)
    this.cleanupEventListeners()
  }

  // Called when any target is added/removed
  targetConnected(target, name) {
    console.log(`Target "${name}" connected:`, target)
  }

  targetDisconnected(target, name) {
    console.log(`Target "${name}" disconnected:`, target)
  }
}
```

**Lifecycle in Turbo Context:**
- Page load → `connect()` called for all controllers
- Turbo Frame update → controllers in updated frame disconnect → new controllers connect
- Turbo Stream append → new controller instances created
- Important: Clean up in `disconnect()` (remove event listeners, observers, timers)

---

## Controller Reference Guide

### 1. Chat Scroll Controller

**Purpose:** Auto-scroll chat to bottom as messages arrive

**File:** `app/javascript/controllers/chat_scroll_controller.js`

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]
  static values = {
    autoScroll: { type: Boolean, default: true }
  }

  connect() {
    this.scrollToBottom()
    this.observeMutations()
    this.observeScroll()
  }

  disconnect() {
    this.mutationObserver?.disconnect()
    this.scrollObserver?.disconnect()
  }

  // Observe new messages being added
  observeMutations() {
    this.mutationObserver = new MutationObserver((mutations) => {
      if (this.autoScrollValue) {
        this.scrollToBottom()
      }
    })

    this.mutationObserver.observe(this.containerTarget, {
      childList: true,
      subtree: true
    })
  }

  // Detect if user scrolled up
  observeScroll() {
    this.containerTarget.addEventListener("scroll", this.handleScroll.bind(this))
  }

  handleScroll() {
    const { scrollTop, scrollHeight, clientHeight } = this.containerTarget
    const isNearBottom = scrollHeight - scrollTop - clientHeight < 100

    this.autoScrollValue = isNearBottom

    // Visual indicator when not auto-scrolling
    this.toggleScrollIndicator(!isNearBottom)
  }

  scrollToBottom() {
    this.containerTarget.scrollTop = this.containerTarget.scrollHeight
  }

  // User clicks "scroll to bottom" button
  forceScrollToBottom() {
    this.autoScrollValue = true
    this.scrollToBottom()
  }

  toggleScrollIndicator(show) {
    const indicator = this.element.querySelector("[data-scroll-indicator]")
    if (indicator) {
      indicator.classList.toggle("hidden", !show)
    }
  }
}
```

**Usage:**
```erb
<div data-controller="chat-scroll"
     data-chat-scroll-target="container"
     class="overflow-y-auto h-full">
  <%= turbo_stream_from "task_#{@task.id}" %>
  <div id="messages">
    <!-- Messages appended here -->
  </div>

  <!-- Optional: Scroll indicator -->
  <button data-scroll-indicator
          data-action="click->chat-scroll#forceScrollToBottom"
          class="hidden fixed bottom-20 right-4 btn btn-sm btn-circle">
    ↓
  </button>
</div>
```

---

### 2. Tree Navigation Controller

**Purpose:** Keyboard navigation for artifact tree (arrow keys, Enter, Esc)

**File:** `app/javascript/controllers/tree_navigation_controller.js`

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item", "tree"]

  connect() {
    this.currentIndex = this.findActiveIndex()
    this.focusItem(this.currentIndex)

    // Listen for keyboard events on tree container
    this.treeTarget.addEventListener("keydown", this.handleKeydown.bind(this))
    this.treeTarget.setAttribute("tabindex", "0")
  }

  disconnect() {
    this.treeTarget.removeEventListener("keydown", this.handleKeydown)
  }

  handleKeydown(event) {
    const handlers = {
      "ArrowDown": () => this.moveDown(),
      "ArrowUp": () => this.moveUp(),
      "ArrowRight": () => this.expand(),
      "ArrowLeft": () => this.collapse(),
      "Enter": () => this.select(),
      "Escape": () => this.blur()
    }

    const handler = handlers[event.key]
    if (handler) {
      event.preventDefault()
      handler()
    }
  }

  moveDown() {
    const visibleItems = this.getVisibleItems()
    if (this.currentIndex < visibleItems.length - 1) {
      this.currentIndex++
      this.focusItem(this.currentIndex)
    }
  }

  moveUp() {
    if (this.currentIndex > 0) {
      this.currentIndex--
      this.focusItem(this.currentIndex)
    }
  }

  expand() {
    const currentItem = this.getCurrentItem()
    const details = currentItem.querySelector("details")

    if (details && !details.open) {
      details.open = true
    } else {
      // If already expanded, move to first child
      this.moveDown()
    }
  }

  collapse() {
    const currentItem = this.getCurrentItem()
    const details = currentItem.closest("details")

    if (details) {
      if (details.open) {
        details.open = false
      } else {
        // If already collapsed, move to parent
        const parentItem = details.closest("li[data-tree-navigation-target='item']")
        if (parentItem) {
          this.currentIndex = this.itemTargets.indexOf(parentItem)
          this.focusItem(this.currentIndex)
        }
      }
    }
  }

  select() {
    const currentItem = this.getCurrentItem()
    const link = currentItem.querySelector("a")

    if (link) {
      link.click()
    }
  }

  blur() {
    this.treeTarget.blur()
  }

  focusItem(index) {
    const visibleItems = this.getVisibleItems()
    const item = visibleItems[index]

    if (!item) return

    // Remove focus from all items
    this.itemTargets.forEach(i => i.classList.remove("focused"))

    // Add focus to current item
    item.classList.add("focused")
    item.scrollIntoView({ block: "nearest", behavior: "smooth" })

    // Store current index
    this.currentIndex = this.itemTargets.indexOf(item)
  }

  getCurrentItem() {
    return this.itemTargets[this.currentIndex]
  }

  getVisibleItems() {
    // Only return items that are not hidden by collapsed <details>
    return this.itemTargets.filter(item => {
      return item.offsetParent !== null
    })
  }

  findActiveIndex() {
    const activeItem = this.itemTargets.find(item => {
      return item.classList.contains("active")
    })

    return activeItem ? this.itemTargets.indexOf(activeItem) : 0
  }
}
```

**Usage:**
```erb
<div data-controller="tree-navigation"
     data-tree-navigation-target="tree"
     class="menu menu-compact">

  <ul>
    <li data-tree-navigation-target="item">
      <details open>
        <summary>Epics (2)</summary>
        <ul>
          <li data-tree-navigation-target="item">
            <%= link_to "001: Bootstrap", epic_path(@epic) %>
          </li>
        </ul>
      </details>
    </li>
  </ul>
</div>
```

**CSS:**
```css
[data-tree-navigation-target="item"].focused {
  outline: 2px solid hsl(var(--p));
  outline-offset: -2px;
  border-radius: 0.5rem;
}
```

---

### 3. Autosave Controller

**Purpose:** Debounced auto-save for forms (2-second delay)

**File:** `app/javascript/controllers/autosave_controller.js`

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "status", "field"]
  static values = {
    delay: { type: Number, default: 2000 },
    url: String
  }

  connect() {
    this.timeout = null
    this.saving = false
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  // Triggered on input events
  handleInput(event) {
    clearTimeout(this.timeout)

    this.showSaving()

    this.timeout = setTimeout(() => {
      this.save()
    }, this.delayValue)
  }

  async save() {
    if (this.saving) return

    this.saving = true

    const url = this.urlValue || this.formTarget.action
    const method = this.formTarget.method || "POST"
    const formData = new FormData(this.formTarget)

    try {
      const response = await fetch(url, {
        method: method,
        body: formData,
        headers: {
          "X-Requested-With": "XMLHttpRequest",
          "Accept": "application/json",
          "X-CSRF-Token": this.csrfToken
        }
      })

      if (response.ok) {
        const data = await response.json()
        this.showSaved(data)
      } else {
        const error = await response.json()
        this.showError(error)
      }
    } catch (error) {
      this.showError(error)
    } finally {
      this.saving = false
    }
  }

  showSaving() {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = "Saving..."
      this.statusTarget.className = "text-sm text-warning"
    }
  }

  showSaved(data) {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = `Saved at ${this.formatTime(new Date())}`
      this.statusTarget.className = "text-sm text-success"

      // Auto-hide after 3 seconds
      setTimeout(() => {
        this.statusTarget.textContent = ""
      }, 3000)
    }

    // Dispatch event for other controllers to react
    this.dispatch("saved", { detail: data })
  }

  showError(error) {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = "Error saving"
      this.statusTarget.className = "text-sm text-error"
    }

    console.error("Autosave error:", error)
    this.dispatch("error", { detail: error })
  }

  formatTime(date) {
    return date.toLocaleTimeString([], {
      hour: "2-digit",
      minute: "2-digit"
    })
  }

  get csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content
  }
}
```

**Usage:**
```erb
<%= form_with model: [@project, @artifact],
    data: {
      controller: "autosave",
      autosave_url_value: project_artifact_path(@project, @artifact),
      action: "input->autosave#handleInput"
    } do |f| %>

  <div class="flex justify-between mb-4">
    <h2>Edit Artifact</h2>
    <span data-autosave-target="status"></span>
  </div>

  <%= f.text_area :content,
      data: { autosave_target: "field" },
      class: "textarea textarea-bordered" %>
<% end %>
```

**Controller Response (JSON):**
```ruby
# app/controllers/artifacts_controller.rb
def update
  if @artifact.update(artifact_params)
    render json: {
      status: 'saved',
      updated_at: @artifact.updated_at.iso8601
    }
  else
    render json: {
      status: 'error',
      errors: @artifact.errors.full_messages
    }, status: :unprocessable_entity
  end
end
```

---

### 4. Modal Controller

**Purpose:** Open/close confirmation dialogs, manage focus trap

**File:** `app/javascript/controllers/modal_controller.js`

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "backdrop"]
  static values = {
    open: { type: Boolean, default: false }
  }

  connect() {
    if (this.openValue) {
      this.open()
    }

    // Close on Escape key
    document.addEventListener("keydown", this.handleEscape.bind(this))
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleEscape)
  }

  open() {
    this.dialogTarget.showModal()
    this.focusFirstInput()
    document.body.classList.add("modal-open")
  }

  close() {
    this.dialogTarget.close()
    document.body.classList.remove("modal-open")
    this.returnFocus()
  }

  handleEscape(event) {
    if (event.key === "Escape" && this.dialogTarget.open) {
      this.close()
    }
  }

  // Click outside modal to close
  handleBackdropClick(event) {
    if (event.target === this.dialogTarget) {
      this.close()
    }
  }

  focusFirstInput() {
    const firstInput = this.dialogTarget.querySelector("input, textarea, select, button")
    if (firstInput) {
      firstInput.focus()
    }
  }

  returnFocus() {
    // Return focus to element that triggered modal
    const trigger = document.activeElement
    if (trigger && trigger.dataset.modalTrigger) {
      trigger.focus()
    }
  }

  // Confirm action before proceeding
  async confirm(message) {
    return new Promise((resolve) => {
      this.dialogTarget.querySelector("[data-modal-message]").textContent = message

      this.dialogTarget.querySelector("[data-modal-confirm]").onclick = () => {
        this.close()
        resolve(true)
      }

      this.dialogTarget.querySelector("[data-modal-cancel]").onclick = () => {
        this.close()
        resolve(false)
      }

      this.open()
    })
  }
}
```

**Usage:**
```erb
<!-- Modal trigger -->
<%= button_to "Delete Artifact",
    project_artifact_path(@project, @artifact),
    method: :delete,
    data: {
      controller: "modal",
      action: "click->modal#open",
      modal_trigger: true
    },
    class: "btn btn-error" %>

<!-- Modal dialog -->
<dialog data-modal-target="dialog"
        data-action="click->modal#handleBackdropClick"
        class="modal">
  <div class="modal-box">
    <h3 class="font-bold text-lg">Confirm Deletion</h3>
    <p class="py-4" data-modal-message>
      Are you sure you want to delete this artifact?
    </p>
    <div class="modal-action">
      <button data-modal-confirm class="btn btn-error">Delete</button>
      <button data-modal-cancel class="btn btn-ghost">Cancel</button>
    </div>
  </div>
</dialog>
```

---

### 5. Command Palette Controller

**Purpose:** Global search/command interface (Cmd+K)

**File:** `app/javascript/controllers/command_palette_controller.js`

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results", "item"]
  static values = {
    searchUrl: String
  }

  connect() {
    document.addEventListener("keydown", this.handleGlobalKeydown.bind(this))
    this.currentIndex = 0
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleGlobalKeydown)
  }

  handleGlobalKeydown(event) {
    // Cmd+K or Ctrl+K to open
    if ((event.metaKey || event.ctrlKey) && event.key === "k") {
      event.preventDefault()
      this.open()
    }

    // / to open (if not in input)
    if (event.key === "/" && !this.isInInput()) {
      event.preventDefault()
      this.open()
    }
  }

  open() {
    this.element.classList.remove("hidden")
    this.inputTarget.focus()
  }

  close() {
    this.element.classList.add("hidden")
    this.inputTarget.value = ""
    this.resultsTarget.innerHTML = ""
  }

  async search(event) {
    const query = event.target.value.trim()

    if (query.length < 2) {
      this.resultsTarget.innerHTML = ""
      return
    }

    try {
      const response = await fetch(`${this.searchUrlValue}?q=${encodeURIComponent(query)}`, {
        headers: { "Accept": "application/json" }
      })

      const data = await response.json()
      this.renderResults(data.results)
    } catch (error) {
      console.error("Search error:", error)
    }
  }

  renderResults(results) {
    this.resultsTarget.innerHTML = results.map((result, index) => `
      <div data-command-palette-target="item"
           data-action="click->command-palette#select"
           data-index="${index}"
           data-url="${result.url}"
           class="p-3 hover:bg-base-200 cursor-pointer ${index === 0 ? 'bg-base-200' : ''}">
        <div class="font-semibold">${result.title}</div>
        <div class="text-sm text-base-content/60">${result.type} · ${result.context}</div>
      </div>
    `).join("")

    this.currentIndex = 0
  }

  handleKeydown(event) {
    switch(event.key) {
      case "ArrowDown":
        event.preventDefault()
        this.moveDown()
        break
      case "ArrowUp":
        event.preventDefault()
        this.moveUp()
        break
      case "Enter":
        event.preventDefault()
        this.selectCurrent()
        break
      case "Escape":
        event.preventDefault()
        this.close()
        break
    }
  }

  moveDown() {
    if (this.currentIndex < this.itemTargets.length - 1) {
      this.currentIndex++
      this.highlightCurrent()
    }
  }

  moveUp() {
    if (this.currentIndex > 0) {
      this.currentIndex--
      this.highlightCurrent()
    }
  }

  highlightCurrent() {
    this.itemTargets.forEach((item, index) => {
      item.classList.toggle("bg-base-200", index === this.currentIndex)
    })
  }

  selectCurrent() {
    const currentItem = this.itemTargets[this.currentIndex]
    if (currentItem) {
      const url = currentItem.dataset.url
      Turbo.visit(url)
      this.close()
    }
  }

  select(event) {
    const url = event.currentTarget.dataset.url
    Turbo.visit(url)
    this.close()
  }

  isInInput() {
    const active = document.activeElement
    return active.tagName === "INPUT" || active.tagName === "TEXTAREA"
  }
}
```

**Usage:**
```erb
<div data-controller="command-palette"
     data-command-palette-search-url-value="<%= search_path %>"
     class="fixed inset-0 z-50 hidden bg-black/50 flex items-start justify-center pt-20">

  <div class="bg-base-100 rounded-lg shadow-xl w-full max-w-2xl">
    <input type="text"
           data-command-palette-target="input"
           data-action="input->command-palette#search keydown->command-palette#handleKeydown"
           placeholder="Search artifacts, files, commands..."
           class="input input-lg input-bordered w-full rounded-t-lg" />

    <div data-command-palette-target="results"
         class="max-h-96 overflow-y-auto">
      <!-- Results rendered here -->
    </div>
  </div>
</div>
```

---

## ActionCable Integration

### Channel Setup

```javascript
// app/javascript/channels/consumer.js
import { createConsumer } from "@hotwired/turbo-rails"

export default createConsumer()
```

```javascript
// app/javascript/channels/task_channel.js
import consumer from "./consumer"

// Subscribe to task updates (streaming messages)
export function subscribeToTask(taskId) {
  return consumer.subscriptions.create(
    { channel: "TaskChannel", task_id: taskId },
    {
      connected() {
        console.log(`Connected to TaskChannel: ${taskId}`)
      },

      disconnected() {
        console.log(`Disconnected from TaskChannel: ${taskId}`)
      },

      received(data) {
        console.log("Received data:", data)

        if (data.type === "message") {
          this.appendMessage(data)
        } else if (data.type === "status") {
          this.updateStatus(data)
        }
      },

      appendMessage(data) {
        // Turbo Streams handle this automatically
        // This is just for logging/debugging
      },

      updateStatus(data) {
        const statusElement = document.querySelector("[data-task-status]")
        if (statusElement) {
          statusElement.textContent = data.status
          statusElement.dataset.status = data.status
        }
      }
    }
  )
}
```

**Usage in Controller:**
```javascript
// app/javascript/controllers/chat_interface_controller.js
import { Controller } from "@hotwired/stimulus"
import { subscribeToTask } from "../channels/task_channel"

export default class extends Controller {
  static values = {
    taskId: String
  }

  connect() {
    this.subscription = subscribeToTask(this.taskIdValue)
  }

  disconnect() {
    this.subscription?.unsubscribe()
  }
}
```

---

## Utility Functions & Helpers

### Debounce Helper

```javascript
// app/javascript/utils/debounce.js
export function debounce(func, delay) {
  let timeout
  return function(...args) {
    clearTimeout(timeout)
    timeout = setTimeout(() => func.apply(this, args), delay)
  }
}
```

### Throttle Helper

```javascript
// app/javascript/utils/throttle.js
export function throttle(func, limit) {
  let inThrottle
  return function(...args) {
    if (!inThrottle) {
      func.apply(this, args)
      inThrottle = true
      setTimeout(() => inThrottle = false, limit)
    }
  }
}
```

### Markdown Parser (Client-Side Preview)

```javascript
// app/javascript/utils/markdown_parser.js
import { marked } from "marked"

export function parseMarkdown(content) {
  return marked.parse(content, {
    breaks: true,
    gfm: true,
    sanitize: false // Server handles sanitization
  })
}
```

---

## Testing Strategy

### Jest + Stimulus Testing Library

**Setup:**
```bash
# Add to package.json (for local dev only)
npm install --save-dev @testing-library/dom @hotwired/stimulus jest
```

**Example Test:**
```javascript
// test/javascript/controllers/chat_scroll_controller.test.js
import { Application } from "@hotwired/stimulus"
import ChatScrollController from "../../../app/javascript/controllers/chat_scroll_controller"

describe("ChatScrollController", () => {
  let application
  let container

  beforeEach(() => {
    container = document.createElement("div")
    container.innerHTML = `
      <div data-controller="chat-scroll">
        <div data-chat-scroll-target="container" style="height: 200px; overflow-y: auto;">
          <div id="messages"></div>
        </div>
      </div>
    `
    document.body.appendChild(container)

    application = Application.start()
    application.register("chat-scroll", ChatScrollController)
  })

  afterEach(() => {
    application.stop()
    document.body.removeChild(container)
  })

  it("scrolls to bottom on new message", async () => {
    const messages = container.querySelector("#messages")
    messages.innerHTML += "<div>New message</div>"

    await new Promise(resolve => setTimeout(resolve, 100))

    const scrollContainer = container.querySelector("[data-chat-scroll-target='container']")
    expect(scrollContainer.scrollTop).toBeGreaterThan(0)
  })
})
```

---

## Performance Optimization

### 1. Lazy Loading Controllers

```javascript
// app/javascript/controllers/index.js
import { application } from "./application"

// Eager load critical controllers
import ChatScrollController from "./chat_scroll_controller"
application.register("chat-scroll", ChatScrollController)

// Lazy load non-critical controllers
const lazyControllers = {
  "command-palette": () => import("./command_palette_controller"),
  "diff-viewer": () => import("./diff_viewer_controller")
}

Object.entries(lazyControllers).forEach(([name, loader]) => {
  application.register(name, class extends Controller {
    async connect() {
      const { default: ControllerClass } = await loader()
      this.realController = new ControllerClass(this.context)
      this.realController.connect()
    }

    disconnect() {
      this.realController?.disconnect()
    }
  })
})
```

### 2. Intersection Observer for Lazy Rendering

```javascript
// app/javascript/controllers/lazy_render_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          this.render()
          this.observer.disconnect()
        }
      })
    })

    this.observer.observe(this.element)
  }

  disconnect() {
    this.observer?.disconnect()
  }

  render() {
    // Load content from data-lazy-url
    const url = this.element.dataset.lazyUrl
    fetch(url)
      .then(response => response.text())
      .then(html => {
        this.element.innerHTML = html
      })
  }
}
```

### 3. Virtual Scrolling for Large Lists

```javascript
// app/javascript/controllers/virtual_scroll_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    itemHeight: { type: Number, default: 60 },
    bufferSize: { type: Number, default: 10 }
  }

  connect() {
    this.items = Array.from(this.element.querySelectorAll("[data-item]"))
    this.visibleItems = new Set()

    this.render()
    this.element.addEventListener("scroll", this.handleScroll.bind(this))
  }

  handleScroll() {
    requestAnimationFrame(() => this.render())
  }

  render() {
    const scrollTop = this.element.scrollTop
    const containerHeight = this.element.clientHeight

    const startIndex = Math.floor(scrollTop / this.itemHeightValue) - this.bufferSizeValue
    const endIndex = Math.ceil((scrollTop + containerHeight) / this.itemHeightValue) + this.bufferSizeValue

    for (let i = 0; i < this.items.length; i++) {
      const item = this.items[i]
      const shouldBeVisible = i >= startIndex && i <= endIndex

      if (shouldBeVisible && !this.visibleItems.has(i)) {
        item.style.display = ""
        this.visibleItems.add(i)
      } else if (!shouldBeVisible && this.visibleItems.has(i)) {
        item.style.display = "none"
        this.visibleItems.delete(i)
      }
    }
  }
}
```

---

## Debugging & Development

### Browser DevTools

**Stimulus Inspector:**
```javascript
// In browser console
Stimulus.controllers
  .filter(c => c.identifier === "chat-scroll")
  .forEach(c => console.log(c))
```

**Turbo Debugging:**
```javascript
// Enable Turbo debug mode
document.addEventListener("turbo:before-fetch-request", (event) => {
  console.log("Turbo fetch:", event.detail.url)
})

document.addEventListener("turbo:frame-load", (event) => {
  console.log("Frame loaded:", event.target.id)
})
```

### Logging Conventions

```javascript
// app/javascript/controllers/base_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  log(...args) {
    if (this.debug) {
      console.log(`[${this.identifier}]`, ...args)
    }
  }

  error(...args) {
    console.error(`[${this.identifier}]`, ...args)
  }

  get debug() {
    return document.documentElement.dataset.debug === "true"
  }
}
```

**Enable in development:**
```erb
<!-- app/views/layouts/application.html.erb -->
<html data-debug="<%= Rails.env.development? %>">
```

---

## Summary

This JavaScript architecture provides:

1. **Stimulus-first approach** for progressive enhancement
2. **Controller reference** with full implementations
3. **ActionCable integration** for real-time updates
4. **Utility functions** for common patterns
5. **Testing strategy** with Jest
6. **Performance optimizations** (lazy loading, virtual scrolling)
7. **Debugging tools** for development

**Next Steps:**
1. Implement controllers in order of priority (chat-scroll → autosave → modal)
2. Write tests for each controller
3. Optimize for production (minification via import maps)

**Status:** Ready for implementation

---

**Document Version:** 1.0
**Last Updated:** 2026-02-08
**Maintained By:** Junie (Claude Sonnet 4.5)
