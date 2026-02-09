# Epic 002: Component Responsibility Matrix

**Epic ID:** 002-UI-Foundation
**Document:** Component Responsibilities & Boundaries
**Created:** 2026-02-08
**Last Updated:** 2026-02-08

---

## Table of Contents

1. [Overview](#overview)
2. [Component Responsibility Definitions](#component-responsibility-definitions)
3. [ViewComponent Layer](#viewcomponent-layer)
4. [Controller Layer](#controller-layer)
5. [Service Layer](#service-layer)
6. [Stimulus Controller Layer](#stimulus-controller-layer)
7. [Cross-Layer Communication Patterns](#cross-layer-communication-patterns)
8. [Decision Tree: Where Does This Logic Go?](#decision-tree-where-does-this-logic-go)

---

## Overview

This matrix defines **strict boundaries** between layers to prevent:
- Business logic in ViewComponents
- Rendering logic in Services
- Data fetching in Stimulus controllers
- State management in JavaScript

### The MVCS Stack

```
┌─────────────────────────────────────────────────────┐
│ Browser (Stimulus Controllers)                      │
│ • UI behavior (keyboard nav, auto-scroll)           │
│ • Client-side state (scroll position, focus)        │
│ • Event handling (clicks, key presses)              │
└─────────────────────────────────────────────────────┘
                    ▲ ▼ (HTML/Turbo Streams)
┌─────────────────────────────────────────────────────┐
│ View Layer (ViewComponents)                         │
│ • Rendering HTML from data                          │
│ • Presentation logic (formatting, icons, badges)    │
│ • No data fetching, no business logic               │
└─────────────────────────────────────────────────────┘
                    ▲ ▼ (method calls)
┌─────────────────────────────────────────────────────┐
│ Controller Layer (Rails Controllers)                │
│ • HTTP routing and params handling                  │
│ • Delegates to Services for business logic          │
│ • Renders responses (Turbo Streams, JSON, HTML)     │
└─────────────────────────────────────────────────────┘
                    ▲ ▼ (method calls)
┌─────────────────────────────────────────────────────┐
│ Service Layer (POROs, Adapters, Agents)             │
│ • Business logic (create epic, process command)     │
│ • External API calls (AiderDesk, ai-agents)         │
│ • Orchestration (multi-step workflows)              │
└─────────────────────────────────────────────────────┘
                    ▲ ▼ (Active Record)
┌─────────────────────────────────────────────────────┐
│ Model Layer (Active Record)                         │
│ • Data persistence (JSONB documents)                │
│ • Validations, associations, callbacks              │
│ • Simple queries (complex queries in Service)       │
└─────────────────────────────────────────────────────┘
```

---

## Component Responsibility Definitions

### ✅ Allowed Responsibilities

| Layer | Allowed |
|-------|---------|
| **ViewComponent** | Render HTML, format data (dates, currency), conditionally show/hide elements, loop over collections, call helpers |
| **Controller** | Parse params, validate HTTP concerns, delegate to services, render responses, handle Turbo Streams |
| **Service** | Business logic, multi-step workflows, external API calls, complex validations, transaction management |
| **Stimulus** | UI behavior, event handling, DOM manipulation, client-side state (scroll position, open/closed) |
| **Model** | CRUD operations, simple validations, associations, callbacks (disk sync, state transitions) |

### ❌ Prohibited Responsibilities

| Layer | Prohibited |
|-------|------------|
| **ViewComponent** | Database queries, API calls, business logic, modifying data, session management |
| **Controller** | Business logic, direct model manipulation (beyond CRUD), external API calls, complex calculations |
| **Service** | Rendering HTML, HTTP concerns (cookies, headers), DOM manipulation, client-side state |
| **Stimulus** | Business logic, server-side state, database queries, authentication/authorization |
| **Model** | Rendering views, HTTP concerns, external API calls (should delegate to Service) |

---

## ViewComponent Layer

### Layouts::DashboardComponent

**File:** `app/components/layouts/dashboard_component.rb`

**Responsibilities:**
- ✅ Render 4-pane grid layout (navbar, sidebar, chat, viewer)
- ✅ Set up Turbo Frame targets (`artifact_tree`, `artifact_viewer`, `chat_messages`)
- ✅ Apply responsive CSS classes based on viewport size
- ✅ Render child components (NavbarComponent, TreeComponent, etc.)

**Does NOT:**
- ❌ Fetch project data (passed as prop from controller)
- ❌ Determine which artifact is active (controller passes `current_artifact`)
- ❌ Handle authentication (controller checks `current_user`)
- ❌ Manage WebSocket subscriptions (Stimulus handles)

**Props:**
```ruby
def initialize(project:, current_artifact: nil, current_task: nil, current_user:)
  @project = project
  @current_artifact = current_artifact
  @current_task = current_task
  @current_user = current_user
end
```

**Template:**
```erb
<div class="grid grid-cols-1 lg:grid-cols-[280px_1fr_480px] h-screen">
  <%= render Layouts::NavbarComponent.new(
        project: @project,
        current_user: @current_user
      ) %>

  <%= render Artifacts::TreeComponent.new(
        project: @project,
        current_artifact: @current_artifact
      ) %>

  <%= render Chat::InterfaceComponent.new(
        project: @project,
        task: @current_task
      ) %>

  <%= turbo_frame_tag "artifact_viewer", class: "bg-base-100" do %>
    <% if @current_artifact %>
      <%= render Artifacts::ViewerComponent.new(artifact: @current_artifact) %>
    <% else %>
      <p class="p-6 text-center text-base-content/60">
        Select an artifact to view details
      </p>
    <% end %>
  <% end %>
</div>
```

---

### Artifacts::TreeComponent

**File:** `app/components/artifacts/tree_component.rb`

**Responsibilities:**
- ✅ Render hierarchical artifact list (grouped by type)
- ✅ Display status badges (draft/refined/approved)
- ✅ Show child counts (Epic has 5 PRDs)
- ✅ Highlight current artifact
- ✅ Format artifact titles (truncate, escape HTML)

**Does NOT:**
- ❌ Filter artifacts by criteria (controller passes filtered collection)
- ❌ Determine user permissions (controller checks authorization)
- ❌ Create new artifacts (delegated to service)
- ❌ Handle click events (uses standard Rails link helpers with Turbo Frame targets)

**Props:**
```ruby
def initialize(project:, current_artifact: nil, artifacts: nil)
  @project = project
  @current_artifact = current_artifact
  @artifacts = artifacts || project.artifacts.includes(:children)
end

def grouped_artifacts
  @artifacts.group_by(&:artifact_type)
end

def status_badge(artifact)
  case artifact.status
  when 'draft'
    tag.span("Draft", class: "badge badge-warning badge-xs")
  when 'refined'
    tag.span("Refined", class: "badge badge-info badge-xs")
  when 'approved'
    tag.span("Approved", class: "badge badge-success badge-xs")
  end
end

def icon_for(type)
  icons = {
    'idea' => '💡',
    'backlog' => '📝',
    'epic' => '📋',
    'prd' => '📄'
  }
  icons[type] || '📁'
end
```

---

### Chat::BubbleComponent

**File:** `app/components/chat/bubble_component.rb`

**Responsibilities:**
- ✅ Render single message bubble (user or assistant)
- ✅ Format message content as Markdown
- ✅ Display timestamp as relative time ("2 minutes ago")
- ✅ Show tool calls (collapsed by default)
- ✅ Apply CSS classes based on role (chat-end vs chat-start)

**Does NOT:**
- ❌ Parse slash commands (Service layer)
- ❌ Send messages (Controller handles POST)
- ❌ Fetch message history (Controller queries database)
- ❌ Manage streaming state (Stimulus + Turbo Streams)

**Props:**
```ruby
def initialize(message:)
  @message = message
end

def role_class
  @message.role == 'user' ? 'chat-end' : 'chat-start'
end

def avatar_color
  @message.role == 'user' ? 'bg-primary' : 'bg-secondary'
end

def formatted_timestamp
  time_ago_in_words(@message.created_at) + " ago"
end

def rendered_content
  sanitize Commonmarker.to_html(@message.content, options: {
    parse: { smart: true },
    render: { unsafe: false }
  })
end
```

---

### Artifacts::DiffPreviewComponent

**File:** `app/components/artifacts/diff_preview_component.rb`

**Responsibilities:**
- ✅ Render unified or side-by-side diff view
- ✅ Syntax highlight code blocks
- ✅ Display diff stats (+42 -8)
- ✅ Show file path and line numbers
- ✅ Render Accept/Reject buttons

**Does NOT:**
- ❌ Apply diffs to files (DiffService handles)
- ❌ Generate diffs (AiderDeskAdapter returns diffs)
- ❌ Validate file paths (Service validates)
- ❌ Execute git operations (GitService or AiderDesk)

**Props:**
```ruby
def initialize(diff:, artifact: nil)
  @diff = diff # { original:, updated:, path:, hunks: }
  @artifact = artifact
end

def diff_stats
  additions = @diff[:hunks].sum { |h| h[:added_lines].count }
  deletions = @diff[:hunks].sum { |h| h[:removed_lines].count }

  { additions: additions, deletions: deletions }
end

def syntax_highlighted_hunk(hunk)
  # Use rouge gem for syntax highlighting
  lexer = Rouge::Lexer.guess(filename: @diff[:path])
  formatter = Rouge::Formatters::HTML.new

  hunk[:lines].map do |line|
    highlighted = formatter.format(lexer.lex(line[:content]))
    { type: line[:type], content: highlighted }
  end
end
```

---

## Controller Layer

### ArtifactsController

**File:** `app/controllers/artifacts_controller.rb`

**Responsibilities:**
- ✅ Route requests to appropriate actions
- ✅ Parse and validate params
- ✅ Authorize user access (via Pundit policy)
- ✅ Delegate to services for business logic
- ✅ Render Turbo Streams or JSON responses
- ✅ Handle errors gracefully

**Does NOT:**
- ❌ Generate artifact content (PlannerAgent service does)
- ❌ Parse slash commands (Coordinator service does)
- ❌ Apply diffs (DiffService does)
- ❌ Call AiderDesk directly (AiderDeskAdapter does)

**Example:**
```ruby
class ArtifactsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_artifact, only: [:show, :edit, :update, :destroy]

  # GET /projects/:project_id/artifacts/:id
  def show
    authorize @artifact

    respond_to do |format|
      format.html {
        render turbo_frame_tag("artifact_viewer") do
          render Artifacts::ViewerComponent.new(artifact: @artifact)
        end
      }
      format.json { render json: @artifact }
    end
  end

  # PATCH /projects/:project_id/artifacts/:id
  def update
    authorize @artifact

    # Delegate to service for business logic
    result = ArtifactUpdater.new(@artifact, current_user)
                            .update(artifact_params)

    respond_to do |format|
      if result.success?
        format.turbo_stream {
          render turbo_stream: [
            turbo_stream.replace("artifact_viewer",
              partial: "artifacts/viewer",
              locals: { artifact: @artifact }
            ),
            turbo_stream.replace("artifact_tree_item_#{@artifact.id}",
              partial: "artifacts/tree_item",
              locals: { artifact: @artifact }
            )
          ]
        }
        format.json { render json: { status: 'saved' } }
      else
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "artifact_editor",
            partial: "artifacts/editor",
            locals: { artifact: @artifact, errors: result.errors }
          )
        }
        format.json { render json: { errors: result.errors }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_project
    @project = current_user.projects.find(params[:project_id])
  end

  def set_artifact
    @artifact = @project.artifacts.find(params[:id])
  end

  def artifact_params
    params.require(:artifact).permit(:title, :status, document: {})
  end
end
```

---

### MessagesController

**File:** `app/controllers/messages_controller.rb`

**Responsibilities:**
- ✅ Receive chat messages via POST
- ✅ Validate message content
- ✅ Delegate to Coordinator service for processing
- ✅ Broadcast Turbo Stream updates
- ✅ Handle streaming responses (via ActionCable)

**Does NOT:**
- ❌ Parse slash commands (Coordinator does)
- ❌ Call AI agents directly (Coordinator orchestrates)
- ❌ Generate artifacts (PlannerAgent does)
- ❌ Execute AiderDesk tasks (CoderAgent → AiderDeskAdapter does)

**Example:**
```ruby
class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project_and_task

  # POST /projects/:project_id/tasks/:task_id/messages
  def create
    authorize @task, :create_message?

    # Save user message
    @user_message = @task.messages.create!(
      role: 'user',
      content: message_params[:content],
      user: current_user
    )

    # Delegate to service
    ProcessMessageJob.perform_later(@task.id, @user_message.id)

    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: turbo_stream.append(
          "messages",
          partial: "messages/bubble",
          locals: { message: @user_message }
        )
      }
      format.json { render json: { message_id: @user_message.id }, status: :created }
    end
  end

  private

  def set_project_and_task
    @project = current_user.projects.find(params[:project_id])
    @task = @project.tasks.find(params[:task_id])
  end

  def message_params
    params.require(:message).permit(:content)
  end
end
```

---

## Service Layer

### Coordinator

**File:** `app/services/coordinator.rb`

**Responsibilities:**
- ✅ Parse slash commands from chat messages
- ✅ Route commands to appropriate agents (Planner, Coder, Reviewer)
- ✅ Orchestrate multi-step workflows (create epic → generate PRDs)
- ✅ Handle normal conversational messages
- ✅ Log all actions to task log

**Does NOT:**
- ❌ Render HTML (ViewComponents do)
- ❌ Handle HTTP requests (Controllers do)
- ❌ Directly manipulate DOM (Stimulus does)
- ❌ Manage sessions/cookies (Controllers do)

**Example:**
```ruby
class Coordinator
  SLASH_COMMANDS = {
    '/new-epic' => :create_epic,
    '/implement' => :implement_artifact,
    '/refine' => :refine_artifact,
    '/search' => :search_artifacts
  }.freeze

  def initialize(project, task, user)
    @project = project
    @task = task
    @user = user
  end

  def process_message(content)
    if content.start_with?('/')
      process_slash_command(content)
    else
      process_conversation(content)
    end
  end

  private

  def process_slash_command(content)
    command, args = parse_command(content)

    handler = SLASH_COMMANDS[command]
    raise InvalidCommandError, "Unknown command: #{command}" unless handler

    send(handler, args)
  end

  def create_epic(description)
    # Use ai-agents gem to invoke PlannerAgent
    agent = PlannerAgent.new(model: @project.primary_model)
    result = agent.generate_epic(description)

    # Create artifact
    artifact = @project.artifacts.create!(
      artifact_type: 'epic',
      title: result[:title],
      jsonb_document: result[:sections],
      status: 'draft',
      created_by: @user
    )

    # Save assistant message
    @task.messages.create!(
      role: 'assistant',
      content: "Created Epic: #{artifact.title}",
      metadata: { artifact_id: artifact.id }
    )

    # Return for controller to broadcast
    { artifact: artifact, message: "Epic created successfully" }
  end

  def implement_artifact(artifact_id)
    artifact = @project.artifacts.find(artifact_id)

    # Hand off to Coder agent
    coder = CoderAgent.new(model: @project.coder_model)
    result = coder.implement(artifact, task: @task)

    # Queue AiderDesk task
    adapter = SmartProxy::AiderDeskAdapter.new(@project.project_dir)
    aider_result = adapter.run_prompt(
      task_id: @task.aider_task_id,
      prompt: result[:implementation_prompt],
      mode: 'code'
    )

    # Return diffs for preview
    { diffs: aider_result[:diffs], artifact: artifact }
  end

  def parse_command(content)
    command, args = content.split(' ', 2)
    [command, args&.strip]
  end
end
```

---

### ArtifactUpdater

**File:** `app/services/artifact_updater.rb`

**Responsibilities:**
- ✅ Update artifact JSONB document
- ✅ Validate section content
- ✅ Trigger disk sync (export to Markdown)
- ✅ Log changes to audit trail
- ✅ Handle version control (if enabled)

**Does NOT:**
- ❌ Render forms (ViewComponents do)
- ❌ Parse HTTP params (Controllers do)
- ❌ Broadcast Turbo Streams (Controllers do)
- ❌ Manage user sessions (Controllers do)

**Example:**
```ruby
class ArtifactUpdater
  def initialize(artifact, user)
    @artifact = artifact
    @user = user
  end

  def update(params)
    @artifact.assign_attributes(params)

    if @artifact.valid?
      ActiveRecord::Base.transaction do
        @artifact.save!
        export_to_markdown
        log_change
      end

      Result.success(artifact: @artifact)
    else
      Result.failure(errors: @artifact.errors.full_messages)
    end
  end

  private

  def export_to_markdown
    exporter = ArtifactExporter.new(@artifact)
    exporter.export_to_disk
  end

  def log_change
    @artifact.versions.create!(
      user: @user,
      changes: @artifact.previous_changes,
      timestamp: Time.current
    )
  end

  class Result
    attr_reader :artifact, :errors

    def initialize(success:, artifact: nil, errors: [])
      @success = success
      @artifact = artifact
      @errors = errors
    end

    def success?
      @success
    end

    def self.success(artifact:)
      new(success: true, artifact: artifact)
    end

    def self.failure(errors:)
      new(success: false, errors: errors)
    end
  end
end
```

---

## Stimulus Controller Layer

### ChatScrollController

**File:** `app/javascript/controllers/chat_scroll_controller.js`

**Responsibilities:**
- ✅ Auto-scroll chat to bottom when new messages arrive
- ✅ Detect if user has scrolled up (disable auto-scroll)
- ✅ Show "scroll to bottom" button when not at bottom
- ✅ Handle smooth scrolling animations

**Does NOT:**
- ❌ Send messages to server (Rails form submission does)
- ❌ Parse message content (Server does)
- ❌ Store message history (Database does)
- ❌ Authenticate users (Server does)

**Data Flow:**
1. Server broadcasts Turbo Stream (new message)
2. Turbo appends message to DOM
3. MutationObserver detects change
4. Controller scrolls to bottom (if auto-scroll enabled)

---

### AutosaveController

**File:** `app/javascript/controllers/autosave_controller.js`

**Responsibilities:**
- ✅ Debounce input events (2-second delay)
- ✅ Submit form data via fetch
- ✅ Show "Saving..." / "Saved" status
- ✅ Handle errors gracefully

**Does NOT:**
- ❌ Validate business rules (Server validates)
- ❌ Transform data (Server does)
- ❌ Persist to database (Server does)
- ❌ Broadcast updates to other users (ActionCable does)

**Data Flow:**
1. User types in textarea
2. Controller debounces input event
3. After 2 seconds, submits form via fetch
4. Server validates and saves
5. Server responds with JSON `{ status: 'saved' }`
6. Controller shows "Saved" indicator

---

## Cross-Layer Communication Patterns

### Pattern 1: User Creates Artifact

```
User clicks "Create Epic" button
  ↓
Controller: ArtifactsController#new
  • Authorizes user
  • Renders form (ViewComponent)
  ↓
User submits form
  ↓
Controller: ArtifactsController#create
  • Parses params
  • Delegates to ArtifactCreator service
  ↓
Service: ArtifactCreator
  • Validates input
  • Calls PlannerAgent (ai-agents gem)
  • Creates Artifact model
  • Exports to Markdown
  ↓
Controller: ArtifactsController#create
  • Broadcasts Turbo Stream
  ↓
Browser: Turbo appends new tree item
  ↓
Stimulus: TreeNavigationController
  • Detects new item
  • Scrolls into view
```

### Pattern 2: User Sends Chat Message

```
User types message, presses Enter
  ↓
Stimulus: SlashCommandsController
  • Detects slash command (optional)
  • Shows autocomplete
  ↓
Form submits to MessagesController#create
  ↓
Controller: MessagesController
  • Saves user message to database
  • Queues ProcessMessageJob
  • Broadcasts user message via Turbo Stream
  ↓
Job: ProcessMessageJob
  • Calls Coordinator service
  ↓
Service: Coordinator
  • Parses command or processes conversation
  • Calls appropriate agent (Planner, Coder, etc.)
  • Saves assistant response
  • Broadcasts via ActionCable
  ↓
Browser: Turbo Stream appends assistant message
  ↓
Stimulus: ChatScrollController
  • Detects new message
  • Scrolls to bottom
```

### Pattern 3: User Accepts Diff

```
User clicks "Accept & Apply" button
  ↓
Stimulus: ModalController
  • Shows confirmation dialog
  ↓
User confirms
  ↓
Form submits to DiffsController#apply
  ↓
Controller: DiffsController
  • Authorizes user
  • Delegates to DiffService
  ↓
Service: DiffService
  • Validates file paths (inside projects/ only)
  • Calls AiderDeskAdapter to apply diff
  ↓
Adapter: SmartProxy::AiderDeskAdapter
  • Sends POST /api/project/apply-edits to AiderDesk
  • Returns result
  ↓
Controller: DiffsController
  • Broadcasts Turbo Stream (success banner)
  • Updates artifact viewer
  ↓
Browser: Turbo replaces viewer pane
  ↓
Stimulus: ToastController
  • Shows success toast
  • Auto-hides after 3 seconds
```

---

## Decision Tree: Where Does This Logic Go?

### Question 1: Does it involve rendering HTML?

**Yes** → ViewComponent
- Formatting data for display (dates, currency)
- Conditionally showing/hiding elements
- Looping over collections
- Applying CSS classes based on state

**No** → Continue to Question 2

---

### Question 2: Does it involve HTTP requests/responses?

**Yes** → Controller
- Parsing params
- Setting cookies/headers
- Rendering Turbo Streams
- Handling errors (404, 422, 500)

**No** → Continue to Question 3

---

### Question 3: Does it involve business logic or external APIs?

**Yes** → Service
- Multi-step workflows
- Calling AI agents
- AiderDesk API calls
- Complex validations
- Transaction management

**No** → Continue to Question 4

---

### Question 4: Does it involve UI behavior (client-side only)?

**Yes** → Stimulus Controller
- Auto-scrolling
- Keyboard navigation
- Debounced input
- Modal open/close
- Client-side state (scroll position, open/closed)

**No** → Continue to Question 5

---

### Question 5: Does it involve data persistence?

**Yes** → Model
- CRUD operations
- Associations (has_many, belongs_to)
- Simple validations (presence, format)
- Callbacks (after_save, before_destroy)

**No** → Helper or Utility Function

---

## Examples with Decisions

### Example 1: "Format artifact created_at as relative time"

**Decision:** ViewComponent (presentation logic)

```ruby
# app/components/artifacts/tree_item_component.rb
def formatted_timestamp
  time_ago_in_words(@artifact.created_at) + " ago"
end
```

**NOT in:**
- Model (not data persistence)
- Service (not business logic)
- Controller (not HTTP concern)

---

### Example 2: "Parse slash command from user message"

**Decision:** Service (business logic)

```ruby
# app/services/coordinator.rb
def parse_slash_command(content)
  command, args = content.split(' ', 2)
  [command, args&.strip]
end
```

**NOT in:**
- ViewComponent (not rendering)
- Controller (too much business logic)
- Model (not data-related)

---

### Example 3: "Auto-scroll chat when new message arrives"

**Decision:** Stimulus Controller (UI behavior)

```javascript
// app/javascript/controllers/chat_scroll_controller.js
observeMutations() {
  this.mutationObserver = new MutationObserver(() => {
    if (this.autoScrollValue) {
      this.scrollToBottom()
    }
  })
}
```

**NOT in:**
- ViewComponent (can't observe DOM mutations)
- Service (server-side, can't access DOM)
- Controller (HTTP-only, no client-side behavior)

---

### Example 4: "Validate project directory is inside projects/"

**Decision:** Service (business rule + security)

```ruby
# app/services/smart_proxy/aider_desk_adapter.rb
def validate_project_dir!(path)
  clean_path = Pathname.new(path).cleanpath.to_s

  unless clean_path.start_with?('projects/')
    raise SecurityError, "Project directory must be inside projects/"
  end

  clean_path
end
```

**NOT in:**
- Model (too complex for model validation)
- Controller (business logic, not HTTP concern)
- ViewComponent (not rendering)

---

### Example 5: "Show status badge for artifact"

**Decision:** ViewComponent (presentation logic)

```ruby
# app/components/artifacts/tree_item_component.rb
def status_badge
  case @artifact.status
  when 'draft'
    tag.span("Draft", class: "badge badge-warning badge-xs")
  when 'refined'
    tag.span("Refined", class: "badge badge-info badge-xs")
  when 'approved'
    tag.span("Approved", class: "badge badge-success badge-xs")
  end
end
```

**NOT in:**
- Model (not data persistence)
- Service (not business logic)
- Helper (prefer ViewComponent for reusable presentation)

---

## Summary

This matrix provides:

1. **Clear boundaries** between layers (no overlap)
2. **Decision tree** for "where does this code go?"
3. **Real examples** from agent-forge codebase
4. **Anti-patterns** (what NOT to do)
5. **Communication flows** across layers

**Key Takeaways:**
- ViewComponents = Presentation (HTML, formatting)
- Controllers = HTTP routing (params, responses)
- Services = Business logic (workflows, APIs)
- Stimulus = UI behavior (client-side interactivity)
- Models = Data persistence (CRUD, associations)

**Next Steps:**
1. Use this matrix when implementing Epic 002 PRDs
2. Review code in PRs against these boundaries
3. Refactor violations (e.g., business logic in controllers)

**Status:** Ready for implementation

---

**Document Version:** 1.0
**Last Updated:** 2026-02-08
**Maintained By:** Junie (Claude Sonnet 4.5)
