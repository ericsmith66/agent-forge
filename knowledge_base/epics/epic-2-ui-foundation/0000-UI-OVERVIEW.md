# Epic 002: UI Foundation — Architecture Overview

**Epic ID:** 002-UI-Foundation
**Program:** Bootstrap Agent-Forge MVP
**Created:** 2026-02-08
**Last Updated:** 2026-02-08

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [System Architecture](#system-architecture)
3. [4-Pane Layout Design](#4-pane-layout-design)
4. [Component Architecture](#component-architecture)
5. [JavaScript Architecture](#javascript-architecture)
6. [Separation of Responsibilities](#separation-of-responsibilities)
7. [Data Flow Patterns](#data-flow-patterns)
8. [Technology Stack](#technology-stack)
9. [Accessibility & Responsive Design](#accessibility--responsive-design)
10. [Security & Safety Rails](#security--safety-rails)

---

## Executive Summary

Epic 002 establishes the **UI Foundation** for agent-forge: a Grok-style 4-pane dashboard that enables users to interact with AI agents, manage artifacts (Ideas, Backlogs, Epics, PRDs), and review/approve code changes from the AiderDesk backend.

### Core User Experience

Users interact with agent-forge through a **single-page dashboard** with four main regions:

1. **Top Navbar** — Project switcher, agent status, global search, user menu
2. **Left Sidebar** — Hierarchical artifact tree (collapsible, filterable)
3. **Center Chat Pane** — Grok-style conversational interface with slash commands
4. **Right Viewer/Editor Pane** — Artifact details, diff previews, edit forms

### Key Design Principles

- **Progressive Enhancement**: Base HTML/CSS works without JS; Turbo/Stimulus enhance
- **Mobile-First**: Responsive layout collapses to single-column on small screens
- **Safety-First**: All destructive actions require explicit confirmation
- **Accessibility**: WCAG 2.1 AA compliant (keyboard nav, ARIA, semantic HTML)
- **Separation of Concerns**: ViewComponents for rendering, Stimulus for behavior, Services for business logic

---

## System Architecture

### High-Level Component Stack

```
┌─────────────────────────────────────────────────────────────┐
│                         Browser                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │   Hotwire    │  │   Stimulus   │  │  DaisyUI/Tailwind│  │
│  │   (Turbo)    │  │ Controllers  │  │      (CSS)       │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                           ▲ ▼ (JSON/HTML)
┌─────────────────────────────────────────────────────────────┐
│                    Rails 8 Backend                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │ViewComponents│  │ Controllers  │  │   Services       │  │
│  │  (Rendering) │  │  (Routing)   │  │(Business Logic)  │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │   Models     │  │  Turbo       │  │  ActionCable     │  │
│  │ (JSONB data) │  │  Streams     │  │  (WebSockets)    │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                           ▲ ▼
┌─────────────────────────────────────────────────────────────┐
│                   PostgreSQL (JSONB)                         │
│   artifacts, projects, tasks, messages, users                │
└─────────────────────────────────────────────────────────────┘
```

### Request/Response Flow

**Static Navigation (Turbo Frames):**
```
User clicks artifact link
  → Turbo Frame request (GET /projects/:id/artifacts/:id)
    → ArtifactsController#show
      → Renders Artifacts::ViewerComponent
        → Turbo replaces "artifact_viewer" frame
          → Right pane updates (no full page reload)
```

**Real-Time Updates (Turbo Streams):**
```
User sends chat message
  → POST /projects/:id/tasks/:id/messages
    → MessagesController#create
      → Broadcasts Turbo Stream
        → ActionCable pushes to browser
          → Stimulus appends message bubble
            → Auto-scrolls chat pane
```

---

## 4-Pane Layout Design

### Desktop Layout (≥1024px)

```
┌────────────────────────────────────────────────────────────────┐
│  Top Navbar (64px fixed)                                       │
│  [Logo] [Project Switcher] [Search] [Agent Status] [User Menu]│
├──────────┬─────────────────────────┬───────────────────────────┤
│          │                         │                           │
│  Left    │   Center Chat Pane      │  Right Viewer/Editor Pane │
│  Sidebar │   (50% width)           │  (30% width)              │
│  (20%    │                         │                           │
│  width)  │  [Chat bubbles]         │  [Artifact viewer]        │
│          │  [Streaming response]   │  [Diff preview]           │
│  Tree:   │  [Slash commands]       │  [Edit form]              │
│  ├ Ideas │                         │                           │
│  ├ Epics │  [Input box at bottom]  │  [Action buttons]         │
│  └ PRDs  │                         │                           │
│          │                         │                           │
│  (scroll)│  (scroll, auto-bottom)  │  (scroll)                 │
│          │                         │                           │
└──────────┴─────────────────────────┴───────────────────────────┘
```

### Mobile/Tablet Layout (<1024px)

```
┌─────────────────────────────────┐
│  Top Navbar (with hamburger)    │
│  [☰] [Project] [Agent] [User]   │
├─────────────────────────────────┤
│                                  │
│  Center Chat Pane (full width)  │
│  [Chat bubbles]                  │
│  [Streaming response]            │
│  [Slash commands]                │
│                                  │
│  [Input box at bottom]           │
│                                  │
└─────────────────────────────────┘
   ↓ (Tap artifact link)
┌─────────────────────────────────┐
│  ← Back to Chat                  │
├─────────────────────────────────┤
│                                  │
│  Right Viewer Pane (full width) │
│  [Artifact viewer]               │
│  [Diff preview]                  │
│  [Edit form]                     │
│                                  │
└─────────────────────────────────┘
   ↓ (Tap hamburger)
┌─────────────────────────────────┐
│  Left Sidebar (drawer overlay)  │
│  ├ Ideas                         │
│  ├ Epics                         │
│  └ PRDs                          │
│                                  │
│  [Tap outside to close]          │
└─────────────────────────────────┘
```

### Layout Breakpoints

| Breakpoint | Width | Layout Mode |
|------------|-------|-------------|
| `xs` | 0-639px | Single column, drawer sidebar |
| `sm` | 640-767px | Single column, drawer sidebar |
| `md` | 768-1023px | 2-column (chat + sidebar drawer) |
| `lg` | 1024-1279px | 3-pane (sidebar, chat, viewer) |
| `xl` | 1280px+ | 3-pane with wider viewer |

---

## Component Architecture

### ViewComponent Hierarchy

```
app/components/
├── layouts/
│   ├── dashboard_component.rb              # Main 4-pane layout
│   └── navbar_component.rb                 # Top navigation bar
│
├── artifacts/
│   ├── tree_component.rb                   # Left sidebar tree
│   ├── tree_item_component.rb              # Individual tree node
│   ├── viewer_component.rb                 # Right pane artifact display
│   ├── editor_component.rb                 # Right pane edit form
│   ├── diff_preview_component.rb           # Side-by-side diff viewer
│   └── status_badge_component.rb           # Draft/Refined/Approved badges
│
├── chat/
│   ├── interface_component.rb              # Main chat container
│   ├── bubble_component.rb                 # Single message bubble
│   ├── input_component.rb                  # Message input box
│   ├── task_status_component.rb            # "Task queued" / "Diffs ready"
│   └── tool_calls_component.rb             # Display ai-agents tool calls
│
├── projects/
│   ├── switcher_component.rb               # Dropdown project selector
│   └── card_component.rb                   # Project list item
│
└── shared/
    ├── loading_component.rb                # Spinner/skeleton states
    ├── modal_component.rb                  # Confirmation dialogs
    ├── toast_component.rb                  # Success/error notifications
    └── command_palette_component.rb        # Global search (Cmd+K)
```

### Component Responsibilities

#### 1. `Layouts::DashboardComponent`
**Purpose**: Orchestrates the 4-pane layout
**Props**:
- `project` (Project model)
- `current_artifact` (Artifact model, optional)
- `current_task` (Task model)

**Responsibilities**:
- Renders navbar, sidebar, chat, viewer in responsive grid
- Sets up Turbo Frame targets (`artifact_tree`, `artifact_viewer`, `chat_messages`)
- Initializes Stimulus controllers for layout behavior

**Does NOT**:
- Fetch data (data passed from controller)
- Handle business logic (delegates to services)
- Manage state (state lives in Stimulus controllers or Turbo Frames)

#### 2. `Artifacts::TreeComponent`
**Purpose**: Renders hierarchical artifact list
**Props**:
- `project` (Project model)
- `current_artifact` (Artifact model, optional)

**Responsibilities**:
- Groups artifacts by type (Idea, Epic, PRD)
- Renders nested tree structure with DaisyUI collapse
- Highlights current artifact
- Displays status badges and child counts

**Does NOT**:
- Handle click events (uses standard Rails link helpers with Turbo Frame targets)
- Modify artifacts (read-only rendering)
- Filter/search (filtering done via Stimulus controller)

#### 3. `Artifacts::ViewerComponent`
**Purpose**: Displays artifact content in right pane
**Props**:
- `artifact` (Artifact model)
- `editable` (boolean, default: false)

**Responsibilities**:
- Renders JSONB document sections as formatted Markdown
- Shows metadata (created_at, updated_at, status)
- Provides "Edit" button (links to editor component)
- Exports to Markdown file

**Does NOT**:
- Edit content (delegates to EditorComponent)
- Execute slash commands (that's chat's job)
- Fetch related data beyond artifact model

#### 4. `Chat::InterfaceComponent`
**Purpose**: Main conversational UI
**Props**:
- `project` (Project model)
- `task` (Task model)

**Responsibilities**:
- Renders message history (bubbles)
- Shows streaming indicator when agent is responding
- Provides input box with slash command autocomplete
- Displays task status (queued, processing, diffs_ready)

**Does NOT**:
- Parse slash commands (handled by Coordinator service)
- Make API calls (delegates to MessagesController → Services)
- Manage WebSocket connections (ActionCable does this)

#### 5. `Artifacts::DiffPreviewComponent`
**Purpose**: Side-by-side code diff viewer
**Props**:
- `diff` (Diff model or hash with :original, :updated, :path)
- `artifact` (Artifact model, optional context)

**Responsibilities**:
- Renders unified or side-by-side diff (syntax highlighted)
- Shows file path and line numbers
- Provides Accept/Reject buttons
- Displays diff stats (additions/deletions)

**Does NOT**:
- Apply changes (delegates to DiffService)
- Modify files directly (safety rail: must go through approval flow)
- Handle git operations (AiderDesk or GitService does this)

---

## JavaScript Architecture

### Stimulus Controller Strategy

**Philosophy**: Stimulus controllers add **behavior**, not structure. Structure comes from ViewComponents/HTML.

### Controller Responsibilities Matrix

| Controller | Purpose | Targets | Actions | Events |
|------------|---------|---------|---------|--------|
| `chat-scroll` | Auto-scroll chat to bottom | `container` | `scrollToBottom()` | `turbo:stream-render` |
| `tree-navigation` | Keyboard nav in artifact tree | `tree`, `item` | `navigate(up/down)`, `expand()`, `collapse()` | `keydown` (↑↓←→) |
| `autosave` | Debounced save for editor | `form`, `field` | `save()`, `showSaved()` | `input` (debounced) |
| `modal` | Open/close confirmation dialogs | `dialog`, `trigger` | `open()`, `close()` | `click`, `keydown` (Esc) |
| `command-palette` | Global search (Cmd+K) | `input`, `results` | `search()`, `navigate()`, `select()` | `keydown` (Cmd+K, ↑↓, Enter) |
| `diff-viewer` | Toggle unified/split view | `container`, `view` | `toggleView()`, `highlight()` | `click` |
| `slash-commands` | Autocomplete in chat input | `input`, `suggestions` | `suggest()`, `complete()` | `keydown` (/, ↑↓, Tab) |
| `project-switcher` | Quick project navigation | `dropdown`, `search` | `filter()`, `switch()` | `click`, `input` |
| `toast` | Show/hide notifications | `container`, `toast` | `show()`, `hide()`, `autoHide()` | `turbo:submit-end` |

### Sample Controller Implementation

#### `chat_scroll_controller.js`

```javascript
// app/javascript/controllers/chat_scroll_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]
  static values = {
    autoScroll: { type: Boolean, default: true }
  }

  connect() {
    this.scrollToBottom()
    this.observeMutations()
  }

  disconnect() {
    this.observer?.disconnect()
  }

  observeMutations() {
    this.observer = new MutationObserver(() => {
      if (this.autoScrollValue) {
        this.scrollToBottom()
      }
    })

    this.observer.observe(this.containerTarget, {
      childList: true,
      subtree: true
    })
  }

  scrollToBottom() {
    this.containerTarget.scrollTop = this.containerTarget.scrollHeight
  }

  // Disable auto-scroll when user scrolls up
  handleScroll() {
    const { scrollTop, scrollHeight, clientHeight } = this.containerTarget
    const isAtBottom = scrollHeight - scrollTop - clientHeight < 50

    this.autoScrollValue = isAtBottom
  }
}
```

**Usage in ViewComponent:**
```erb
<div data-controller="chat-scroll"
     data-chat-scroll-target="container"
     data-action="scroll->chat-scroll#handleScroll"
     class="overflow-y-auto h-full">
  <%= turbo_stream_from "task_#{@task.id}" %>
  <div id="messages">
    <% @messages.each do |message| %>
      <%= render Chat::BubbleComponent.new(message: message) %>
    <% end %>
  </div>
</div>
```

#### `autosave_controller.js`

```javascript
// app/javascript/controllers/autosave_controller.js
import { Controller } from "@hotwired/stimulus"
import { debounce } from "../utils/debounce"

export default class extends Controller {
  static targets = ["form", "status"]
  static values = {
    delay: { type: Number, default: 2000 } // 2 seconds
  }

  connect() {
    this.save = debounce(this.save.bind(this), this.delayValue)
  }

  // Triggered on input events
  handleInput() {
    this.showSaving()
    this.save()
  }

  async save() {
    const formData = new FormData(this.formTarget)

    try {
      const response = await fetch(this.formTarget.action, {
        method: this.formTarget.method || "POST",
        body: formData,
        headers: {
          "X-Requested-With": "XMLHttpRequest",
          "Accept": "text/vnd.turbo-stream.html"
        }
      })

      if (response.ok) {
        this.showSaved()
      } else {
        this.showError()
      }
    } catch (error) {
      this.showError(error)
    }
  }

  showSaving() {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = "Saving..."
      this.statusTarget.classList.add("text-warning")
    }
  }

  showSaved() {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = "Saved"
      this.statusTarget.classList.remove("text-warning")
      this.statusTarget.classList.add("text-success")

      setTimeout(() => {
        this.statusTarget.textContent = ""
      }, 2000)
    }
  }

  showError(error) {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = "Error saving"
      this.statusTarget.classList.add("text-error")
    }
    console.error("Autosave error:", error)
  }
}
```

**Usage:**
```erb
<%= form_with model: [@project, @artifact],
    data: {
      controller: "autosave",
      action: "input->autosave#handleInput"
    } do |f| %>

  <div class="flex justify-between items-center mb-4">
    <h2>Edit Artifact</h2>
    <span data-autosave-target="status" class="text-sm"></span>
  </div>

  <%= f.text_area :content,
      data: { autosave_target: "form" },
      class: "textarea textarea-bordered" %>
<% end %>
```

#### `tree_navigation_controller.js`

```javascript
// app/javascript/controllers/tree_navigation_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item"]

  connect() {
    this.currentIndex = 0
    this.focusItem(0)
  }

  // Keyboard navigation
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
      case "ArrowRight":
        event.preventDefault()
        this.expand()
        break
      case "ArrowLeft":
        event.preventDefault()
        this.collapse()
        break
      case "Enter":
        event.preventDefault()
        this.select()
        break
    }
  }

  moveDown() {
    if (this.currentIndex < this.itemTargets.length - 1) {
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
    const currentItem = this.itemTargets[this.currentIndex]
    const details = currentItem.querySelector("details")
    if (details) {
      details.open = true
    }
  }

  collapse() {
    const currentItem = this.itemTargets[this.currentIndex]
    const details = currentItem.querySelector("details")
    if (details) {
      details.open = false
    }
  }

  select() {
    const currentItem = this.itemTargets[this.currentIndex]
    const link = currentItem.querySelector("a")
    if (link) {
      link.click()
    }
  }

  focusItem(index) {
    // Remove focus from all items
    this.itemTargets.forEach(item => item.classList.remove("focused"))

    // Add focus to current item
    const item = this.itemTargets[index]
    item.classList.add("focused")
    item.scrollIntoView({ block: "nearest", behavior: "smooth" })
  }
}
```

### JavaScript File Structure

```
app/javascript/
├── controllers/
│   ├── application.js                 # Stimulus application setup
│   ├── chat_scroll_controller.js
│   ├── tree_navigation_controller.js
│   ├── autosave_controller.js
│   ├── modal_controller.js
│   ├── command_palette_controller.js
│   ├── diff_viewer_controller.js
│   ├── slash_commands_controller.js
│   ├── project_switcher_controller.js
│   └── toast_controller.js
│
├── channels/
│   ├── consumer.js                    # ActionCable consumer
│   ├── task_channel.js                # Subscribe to task updates
│   └── artifact_channel.js            # Subscribe to artifact changes
│
├── utils/
│   ├── debounce.js                    # Debounce helper
│   ├── markdown_parser.js             # Client-side markdown preview
│   └── syntax_highlighter.js          # Code syntax highlighting
│
└── application.js                     # Main entry point
```

---

## Separation of Responsibilities

### The MVCS Pattern (Model-View-Controller-Service)

agent-forge uses a **strict separation** between layers:

```
┌─────────────────────────────────────────────────────────┐
│                      Browser Layer                       │
│  • Stimulus Controllers (UI behavior)                    │
│  • Hotwire Turbo (page updates)                          │
│  • ActionCable (real-time updates)                       │
└─────────────────────────────────────────────────────────┘
                         ▲ ▼ (HTML/JSON/Turbo Streams)
┌─────────────────────────────────────────────────────────┐
│                      View Layer                          │
│  • ViewComponents (rendering logic only)                 │
│  • ERB Templates (markup)                                │
│  • Helpers (presentation formatting)                     │
└─────────────────────────────────────────────────────────┘
                         ▲ ▼ (method calls)
┌─────────────────────────────────────────────────────────┐
│                    Controller Layer                      │
│  • Routes requests to services                           │
│  • Handles HTTP concerns (params, headers)               │
│  • Returns responses (render, redirect, stream)          │
│  • NO business logic (delegate to services)              │
└─────────────────────────────────────────────────────────┘
                         ▲ ▼ (method calls)
┌─────────────────────────────────────────────────────────┐
│                     Service Layer                        │
│  • Business logic (artifact creation, slash commands)    │
│  • Orchestrates agents (Planner, Coder, Reviewer)        │
│  • Calls external APIs (AiderDesk, ai-agents gem)        │
│  • Manages transactions, validations, side effects       │
└─────────────────────────────────────────────────────────┘
                         ▲ ▼ (Active Record)
┌─────────────────────────────────────────────────────────┐
│                      Model Layer                         │
│  • Data persistence (JSONB documents)                    │
│  • Validations (schema enforcement)                      │
│  • Associations (project has_many artifacts)             │
│  • Callbacks (sync_to_disk after_save)                   │
└─────────────────────────────────────────────────────────┘
```

### Example: Creating an Epic via Slash Command

**Flow:**
1. **User types** `/new-epic Build webhook receiver` in chat input
2. **Stimulus controller** (`slash_commands_controller.js`) detects `/` prefix, shows autocomplete
3. **User submits** → POST `/projects/:id/tasks/:id/messages` with content
4. **MessagesController** receives request, saves user message, delegates to service:
   ```ruby
   # app/controllers/messages_controller.rb
   def create
     @message = @task.messages.create!(message_params.merge(role: 'user'))

     # Delegate to service
     result = Coordinator.new(@project, @task).process_message(@message.content)

     # Broadcast response via Turbo Stream
     respond_to do |format|
       format.turbo_stream
     end
   end
   ```
5. **Coordinator service** parses slash command, calls PlannerAgent:
   ```ruby
   # app/services/coordinator.rb
   class Coordinator
     def process_message(content)
       if content.start_with?('/new-epic ')
         description = content.sub('/new-epic ', '')
         create_epic(description)
       else
         # Normal chat
       end
     end

     def create_epic(description)
       # Use ai-agents gem
       agent = PlannerAgent.new
       result = agent.generate_epic(description)

       # Create artifact
       artifact = @project.artifacts.create!(
         artifact_type: 'epic',
         title: result[:title],
         jsonb_document: result[:sections],
         status: 'draft'
       )

       # Return for controller to broadcast
       { artifact: artifact, message: "Created Epic: #{artifact.title}" }
     end
   end
   ```
6. **Controller broadcasts** Turbo Stream to update tree and chat:
   ```ruby
   # app/views/messages/create.turbo_stream.erb
   <%= turbo_stream.append "messages" do %>
     <%= render Chat::BubbleComponent.new(message: @assistant_message) %>
   <% end %>

   <%= turbo_stream.append "artifact_tree_epics" do %>
     <%= render Artifacts::TreeItemComponent.new(artifact: @artifact) %>
   <% end %>
   ```
7. **Browser** receives Turbo Stream, updates DOM, Stimulus `chat-scroll` auto-scrolls

**Responsibilities at each layer:**
- **Stimulus**: Autocomplete UI, submit form
- **Controller**: Routing, response formatting
- **Service**: Business logic (parse command, call agent, create artifact)
- **Model**: Data persistence, validation
- **ViewComponent**: Rendering HTML

**Nobody violates boundaries.** Controllers don't call agents directly. Services don't render HTML. Stimulus doesn't make API calls (except via fetch to Rails endpoints).

---

## Data Flow Patterns

### Pattern 1: Static Navigation (Turbo Frames)

**Use case:** User clicks artifact in tree → load viewer in right pane

```ruby
# app/components/artifacts/tree_item_component.html.erb
<%= link_to project_artifact_path(@project, @artifact),
    data: { turbo_frame: "artifact_viewer" },
    class: "artifact-link" do %>
  <%= @artifact.title %>
<% end %>
```

**Flow:**
1. User clicks link
2. Turbo intercepts click, sends GET request with `Turbo-Frame: artifact_viewer` header
3. Rails responds with HTML fragment wrapped in `<turbo-frame id="artifact_viewer">`
4. Turbo replaces matching frame in DOM
5. Right pane updates, no page reload

**Benefits:**
- Fast (only partial HTML updates)
- History works (back button navigates frames)
- Accessible (works without JS via full page load fallback)

### Pattern 2: Real-Time Updates (Turbo Streams + ActionCable)

**Use case:** Agent sends streaming response → append to chat

```ruby
# app/services/coordinator.rb
def stream_response(content)
  content.each_char do |char|
    sleep 0.02 # Simulate streaming

    Turbo::StreamsChannel.broadcast_append_to(
      "task_#{@task.id}",
      target: "streaming-message-#{@current_message_id}",
      html: char
    )
  end
end
```

**Flow:**
1. Service generates response character-by-character
2. Broadcasts Turbo Stream via ActionCable
3. Browser subscribes to `task_#{id}` channel
4. Each stream appends to DOM
5. Stimulus `chat-scroll` controller scrolls on mutation

**Benefits:**
- Real-time (no polling)
- Efficient (incremental updates)
- Works with Rails conventions (no custom WebSocket code)

### Pattern 3: Form Submission (Turbo + Validation)

**Use case:** User edits artifact → save via AJAX

```ruby
# app/views/artifacts/edit.html.erb
<%= turbo_frame_tag "artifact_viewer" do %>
  <%= form_with model: [@project, @artifact],
      data: { controller: "autosave" } do |f| %>

    <%= f.text_area :content,
        data: { action: "input->autosave#handleInput" } %>

    <%= f.submit "Save", class: "btn btn-primary" %>
  <% end %>
<% end %>
```

**Flow (manual save):**
1. User clicks "Save"
2. Turbo submits form via fetch (POST with Turbo header)
3. Controller validates, saves, responds with Turbo Stream
4. Turbo replaces frame with success message or errors

**Flow (autosave):**
1. User types in textarea
2. Stimulus `autosave` controller debounces input
3. After 2s, submits form via fetch
4. Controller saves, responds with JSON `{ status: 'saved' }`
5. Stimulus shows "Saved" indicator

**Benefits:**
- Progressive enhancement (works without JS)
- Instant feedback (autosave)
- Validation errors inline (Turbo re-renders form with errors)

---

## Technology Stack

### Frontend

| Technology | Purpose | Version |
|------------|---------|---------|
| **Hotwire Turbo** | Page navigation without full reloads | 8.x |
| **Stimulus** | Modest JavaScript framework for behavior | 3.x |
| **DaisyUI** | Component library for Tailwind | 4.x |
| **Tailwind CSS** | Utility-first CSS framework | 3.x |
| **ViewComponent** | Server-rendered component system | 3.x |
| **ActionCable** | WebSocket support for real-time updates | Rails 8 |
| **commonmarker** | Markdown rendering | Rails 8 default |

### Backend

| Technology | Purpose | Version |
|------------|---------|---------|
| **Rails** | MVC framework | 8.1+ |
| **PostgreSQL** | Database with JSONB support | 16+ |
| **Solid Queue** | Background jobs (Rails 8 default) | 8.x |
| **ai-agents gem** | Multi-agent orchestration | 0.7.0+ |
| **HTTParty** | HTTP client for AiderDesk API | Latest |

### Development Tools

| Tool | Purpose |
|------|---------|
| **ViewComponent Previews** | Component development UI |
| **Lookbook** | ViewComponent style guide (optional) |
| **Browser DevTools** | Stimulus debugging, Turbo frame inspection |
| **TailwindCSS IntelliSense** | VS Code extension for class autocomplete |

---

## Accessibility & Responsive Design

### WCAG 2.1 AA Compliance

**Keyboard Navigation:**
- All interactive elements focusable (links, buttons, inputs)
- Focus visible (outline ring in primary color)
- Skip links ("Skip to main content")
- Shortcut keys:
  - `/` — Focus chat input
  - `Cmd+K` — Open command palette
  - `Esc` — Close modal/cancel action
  - Arrow keys — Navigate artifact tree

**Screen Reader Support:**
- Semantic HTML (`<nav>`, `<main>`, `<aside>`, `<article>`)
- ARIA labels on icon-only buttons (`aria-label="Edit artifact"`)
- ARIA live regions for streaming chat (`aria-live="polite"`)
- Role attributes (`role="tree"`, `role="treeitem"` for artifact tree)

**Color Contrast:**
- DaisyUI themes meet WCAG AA (4.5:1 for text, 3:1 for UI components)
- Status badges use both color + text ("Draft", not just yellow)

**Focus Management:**
- After modal opens, focus trap inside modal
- After modal closes, return focus to trigger button
- After form save, focus "Edit" button

### Responsive Design Strategy

**Mobile-First Breakpoints:**
```css
/* Base styles (mobile) */
.dashboard { grid-template-columns: 1fr; }

/* Tablet (md: 768px+) */
@media (min-width: 768px) {
  .dashboard { grid-template-columns: 2fr 1fr; }
}

/* Desktop (lg: 1024px+) */
@media (min-width: 1024px) {
  .dashboard { grid-template-columns: 1fr 2fr 1.5fr; }
}
```

**Touch Targets:**
- Minimum 44×44px for buttons/links (iOS accessibility guideline)
- Increased padding on mobile (`p-4` → `p-6` on `<lg`)

**Drawer Pattern for Sidebar:**
```erb
<!-- DaisyUI drawer component -->
<div class="drawer drawer-mobile">
  <input id="drawer-toggle" type="checkbox" class="drawer-toggle" />

  <!-- Main content (chat + viewer) -->
  <div class="drawer-content">
    <label for="drawer-toggle" class="btn btn-square btn-ghost lg:hidden">
      <svg><!-- Hamburger icon --></svg>
    </label>
    <%= yield :main_content %>
  </div>

  <!-- Sidebar (drawer on mobile, persistent on desktop) -->
  <div class="drawer-side">
    <%= render Artifacts::TreeComponent.new(project: @project) %>
  </div>
</div>
```

**Behavior:**
- Mobile: Sidebar hidden by default, opens as overlay
- Desktop (`lg:drawer-open`): Sidebar always visible, no overlay

---

## Security & Safety Rails

### Never Auto-Apply Destructive Actions

**Rule:** All code changes, deletions, or database modifications require **explicit user confirmation**.

**Implementation:**

1. **Diff Preview Before Apply**
   ```ruby
   # app/controllers/diffs_controller.rb
   def apply
     @diff = Diff.find(params[:id])

     # Require confirmation
     unless params[:confirmed] == 'true'
       redirect_to preview_diff_path(@diff), alert: "Review required"
       return
     end

     # Apply via service
     result = DiffService.new(@diff).apply!

     if result.success?
       redirect_to @diff.artifact, notice: "Changes applied"
     else
       redirect_to preview_diff_path(@diff), alert: result.error
     end
   end
   ```

2. **Confirmation Dialog**
   ```erb
   <%= button_to "Accept & Apply",
       apply_diff_path(@diff, confirmed: true),
       method: :post,
       class: "btn btn-success",
       data: {
         controller: "modal",
         action: "click->modal#confirm",
         modal_message: "Apply these changes to the codebase?"
       } %>
   ```

3. **Visual Warning**
   ```erb
   <div class="alert alert-warning">
     <svg class="stroke-current flex-shrink-0 h-6 w-6">...</svg>
     <span>
       <strong>These changes have NOT been applied.</strong>
       Review carefully before accepting.
     </span>
   </div>
   ```

### Input Sanitization

**Markdown Content:**
```ruby
# app/helpers/artifacts_helper.rb
def render_markdown(content)
  return "" if content.blank?

  # Commonmarker with unsafe HTML disabled for user input
  sanitize Commonmarker.to_html(content, options: {
    parse: { smart: true },
    render: { unsafe: false } # Disable raw HTML
  })
end
```

**Slash Command Parsing:**
```ruby
# app/services/coordinator.rb
def parse_slash_command(content)
  # Whitelist only known commands
  command, args = content.split(' ', 2)

  unless ALLOWED_COMMANDS.include?(command)
    raise InvalidCommandError, "Unknown command: #{command}"
  end

  # Sanitize args (prevent injection)
  sanitized_args = args.gsub(/[^a-zA-Z0-9\s\-_]/, '')

  [command, sanitized_args]
end
```

### Project Directory Validation

**Rule:** Never access files outside `projects/` directory.

```ruby
# app/services/aider_desk_adapter.rb
class SmartProxy::AiderDeskAdapter
  def validate_project_dir!(path)
    clean_path = Pathname.new(path).cleanpath.to_s

    unless clean_path.start_with?('projects/')
      raise SecurityError, "Project directory must be inside projects/"
    end

    unless Dir.exist?(clean_path)
      raise ArgumentError, "Project directory does not exist: #{clean_path}"
    end

    clean_path
  end
end
```

### Rate Limiting (Future)

**For Epic 3+:** Add rate limiting to chat input to prevent spam/abuse.

```ruby
# config/initializers/rack_attack.rb
Rack::Attack.throttle("messages/ip", limit: 60, period: 1.minute) do |req|
  req.ip if req.path.start_with?('/messages') && req.post?
end
```

---

## Next Steps

This UI Overview provides the foundation for:

1. **WIREFRAMES.md** — Detailed screen mockups with pixel dimensions
2. **0000-EPIC-OVERVIEW.md** — Full epic scope, PRD breakdown, timeline
3. **PRD-2-01** through **PRD-2-05** — Individual implementation specs

**Recommended Epic 2 PRD Structure:**
- PRD 2-01: Layout & Navigation (Navbar, Sidebar, Responsive)
- PRD 2-02: Artifact Tree & Viewer Components
- PRD 2-03: Chat Interface & Streaming
- PRD 2-04: Diff Preview & Approval Flow
- PRD 2-05: Command Palette & Keyboard Shortcuts

---

**Document Status:** Draft — Ready for Junie/team review
**Next Action:** Create WIREFRAMES.md with detailed screen layouts
