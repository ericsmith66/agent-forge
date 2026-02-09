#### PRD-2-05: Chat Pane & Message Flow

**PRD ID:** PRD-002.5  
**Version:** 1.0  
**Owner:** Senior Architect  
**Date:** 2026-02-09  
**Branch:** `feat/ui-chat`  
**Dependencies:** PRD-002.2, PRD-002.3

**Log Requirements**
- Junie: read the Junie log requirement doc and create/update a task log under `knowledge_base/prds-junie-log/`.
- In the log, include detailed manual test steps and expected results.
- If asked to review: create a separate document named `PRD-2-05-chat-pane-messages-feedback-V{{N}}.md` in the same directory.

---

### Overview

Build the center chat pane — the primary interaction surface for agent-forge. Users type messages and slash commands here; agents respond with text, status updates, and tool call results. This PRD covers the chat UI components, message persistence, real-time updates via ActionCable/Turbo Streams, and a stub slash command handler that creates artifacts directly (real agent orchestration deferred to Epic 4).

---

### Requirements

#### Functional

- **`Chat::InterfaceComponent`** (`app/components/chat/interface_component.rb`):
  - Renders message history (scrollable, auto-scroll to bottom on new messages).
  - Shows streaming indicator when "agent" is responding.
  - Input box at bottom with submit button.
  - Wrapped in `turbo_frame_tag "chat_messages"`.
  - Props: `task` (Task), `messages` (collection).

- **`Chat::BubbleComponent`** (`app/components/chat/bubble_component.rb`):
  - Renders single message bubble.
  - Styled by role: user (right-aligned, primary color), assistant (left-aligned, secondary), system (centered, muted), tool (left, monospace).
  - Shows timestamp and role label.
  - Renders markdown content (using `render_markdown` helper from PRD-2-06 or inline).
  - Props: `message` (Message model).

- **`Chat::InputComponent`** (`app/components/chat/input_component.rb`):
  - Text input (textarea, auto-resize) with submit button.
  - Form posts to `MessagesController#create`.
  - Clears input after successful submit.
  - Props: `task` (Task).

- **`MessagesController`** (`app/controllers/messages_controller.rb`):
  - `create` action: saves user message, processes via stub coordinator, saves assistant response.
  - Returns Turbo Stream that appends both user and assistant bubbles to chat.
  - Scoped: `POST /projects/:project_id/tasks/:task_id/messages`.

- **Stub Coordinator** (`app/services/coordinator.rb`):
  - Parses basic slash commands: `/new-epic <title>`, `/new-prd <title>`, `/status`, `/help`.
  - `/new-epic` → creates Artifact (type: epic, status: draft) → returns confirmation message.
  - `/new-prd <epic-id> <title>` → creates child PRD artifact → returns confirmation.
  - `/status` → returns project status summary (artifact counts by status).
  - `/help` → returns list of available commands.
  - Non-slash messages → returns canned response: "Agent orchestration coming in Epic 4. For now, use slash commands."
  - All responses saved as assistant Messages.

- **`slash_commands` Stimulus controller** (`app/javascript/controllers/slash_commands_controller.js`):
  - Detects `/` at start of input → shows autocomplete dropdown with available commands.
  - Arrow keys navigate suggestions, Tab/Enter completes.
  - Dropdown dismisses on Escape or clicking outside.

- **`chat_scroll` Stimulus controller** (`app/javascript/controllers/chat_scroll_controller.js`):
  - Auto-scrolls chat container to bottom when new messages appear (MutationObserver).
  - Disables auto-scroll when user scrolls up; re-enables when user scrolls to bottom.

- **ActionCable channel** (`app/channels/task_channel.rb`):
  - Subscribes to `task_#{task.id}`.
  - Broadcasts Turbo Streams when new messages are created.
  - Client subscribes via `turbo_stream_from` helper in InterfaceComponent.

- **Task auto-creation**:
  - When user opens dashboard for a project, ensure a "current task" exists (create one if none).
  - Task is the container for the chat session.

#### Non-Functional

- Messages persist to database (survive page refresh).
- Real-time: new messages appear without page reload (ActionCable + Turbo Streams).
- Input clears after submit; focus returns to input.
- Chat scrolls smoothly; no jank on rapid message appends.
- Accessible: `aria-live="polite"` on message container for screen readers.

#### Rails / Implementation Notes

- `app/components/chat/interface_component.rb` + `.html.erb`
- `app/components/chat/bubble_component.rb` + `.html.erb`
- `app/components/chat/input_component.rb` + `.html.erb`
- `app/controllers/messages_controller.rb`
- `app/services/coordinator.rb`
- `app/channels/task_channel.rb`
- `app/javascript/controllers/chat_scroll_controller.js`
- `app/javascript/controllers/slash_commands_controller.js`
- Routes: `resources :messages, only: [:create]` nested under `resources :tasks` under `resources :projects`.

---

### Error Scenarios & Fallbacks

- **Empty message submitted** → Validation error, input not cleared, inline error shown.
- **Coordinator fails** → Save system message with error text; don't crash chat.
- **ActionCable disconnected** → Messages still save via HTTP POST; user sees them on next page load. Show "Reconnecting..." indicator.
- **Unknown slash command** → Coordinator returns friendly error: "Unknown command. Type /help for available commands."

---

### Architectural Context

The chat pane is the **command center** for user-agent interaction. In Epic 2, the "agent" is a stub coordinator that handles slash commands directly. In Epic 4, this will be replaced by real multi-agent orchestration (Coordinator → Planner → Coder). The UI components and message flow remain the same — only the coordinator service changes.

```
User types "/new-epic Build webhook"
  → Chat::InputComponent (form submit)
    → MessagesController#create
      → Saves user Message
      → Coordinator.process_message("/new-epic Build webhook")
        → Creates Artifact (epic, draft)
        → Returns "Created Epic: Build webhook"
      → Saves assistant Message
      → Broadcasts Turbo Stream (append both bubbles)
    → ActionCable → Browser updates chat
```

---

### Acceptance Criteria

- [ ] Chat pane renders message history for current task.
- [ ] User can type and submit messages; they appear as bubbles.
- [ ] Assistant responses appear after submit (from stub coordinator).
- [ ] `/new-epic My Epic` creates an Epic artifact and confirms in chat.
- [ ] `/new-prd <epic-id> My PRD` creates a child PRD and confirms.
- [ ] `/help` lists available commands.
- [ ] `/status` shows artifact counts.
- [ ] Non-slash messages get canned "coming in Epic 4" response.
- [ ] Messages persist across page refresh.
- [ ] New messages appear in real-time via ActionCable (no page reload).
- [ ] Chat auto-scrolls to bottom on new messages.
- [ ] Slash command autocomplete shows on `/` input.
- [ ] All component, controller, and service tests pass.

---

### Test Cases

#### Unit (Minitest — ViewComponent::TestCase)

- `test/components/chat/interface_component_test.rb`:
  - Renders message list.
  - Contains input form.
  - Contains Turbo Stream subscription.

- `test/components/chat/bubble_component_test.rb`:
  - Renders user bubble (right-aligned, primary).
  - Renders assistant bubble (left-aligned, secondary).
  - Renders system bubble (centered, muted).
  - Renders markdown content.

- `test/components/chat/input_component_test.rb`:
  - Renders textarea and submit button.
  - Form action points to messages create path.

#### Unit (Minitest — Service)

- `test/services/coordinator_test.rb`:
  - `/new-epic Title` creates epic artifact, returns confirmation.
  - `/new-prd <id> Title` creates PRD under epic, returns confirmation.
  - `/status` returns artifact counts.
  - `/help` returns command list.
  - Unknown command returns error message.
  - Non-slash message returns canned response.
  - Invalid `/new-prd` (missing epic-id) returns error.

#### Integration (Minitest)

- `test/integration/messages_controller_test.rb`:
  - POST creates user message and assistant response.
  - POST with `/new-epic` creates artifact + messages.
  - POST with empty content returns error.
  - Response includes Turbo Stream format.

---

### Manual Verification

1. Open dashboard — chat pane visible with input box.
2. Type "hello" and submit — user bubble appears, assistant responds with canned message.
3. Type `/help` — assistant lists available commands.
4. Type `/new-epic Build webhook receiver` — assistant confirms, artifact appears in sidebar tree.
5. Type `/status` — assistant shows artifact counts.
6. Refresh page — all messages still visible.
7. Open browser DevTools → Network → verify ActionCable WebSocket connection.

**Expected**
- Chat is interactive and responsive.
- Slash commands create artifacts.
- Messages persist and stream in real-time.

---

### Implementation Notes for Agents

- Load `.junie/guidelines.md` and `core-agent-instructions.md` first.
- Reference `knowledge_base/epics/epic-2-ui-foundation/JAVASCRIPT-ARCHITECTURE.md` for Stimulus controller specs.
- The stub coordinator is intentionally simple — no AI calls, no agent handoffs. Just direct CRUD.
- When creating artifacts via slash commands, also broadcast a Turbo Stream to update the sidebar tree (`turbo_stream.append "artifact_tree_epics"`).
- Commit message suggestion: `"Implement PRD-002.5: Chat pane, message flow & stub slash commands"`
