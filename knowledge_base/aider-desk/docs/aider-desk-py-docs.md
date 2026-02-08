Got it. Below are **two Markdown docs** you can drop into `knowledge_base/`:

1) **Consumer-friendly**: practical “how to call it” guide with examples and common flows
2) **Schema-accurate**: request shapes (required/optional fields, enums, query vs body) as derived from the server’s route validation

Notes:
- Both docs assume the API is mounted at **`/api`**.
- A few endpoint families are registered but not fully enumerated here yet (**Memory / Voice / Terminal / BMAD**, and possibly additional `ProjectApi` routes past the portion already captured). I marked those clearly as **TODO** sections so the docs are still useful and safe to build against.

```markdown
# AiderDesk REST API — Consumer-Friendly Guide

This is a practical guide for calling the AiderDesk server API from another application.

## Base URL

- Server: `http://localhost:24337`
- API prefix: `http://localhost:24337/api`

All endpoints below are relative to `/api`.

## Authentication

AiderDesk can require **HTTP Basic Auth** depending on configuration (settings) or environment overrides.

Send:
- Header: `Authorization: Basic <base64(username:password)>`

Example (pseudo):
- `username`: `admin`
- `password`: set via your app configuration (don’t hardcode)

If auth is required and missing/invalid:
- `401 Authentication required` or `401 Invalid credentials`

## “Server not started” behavior

If the server is not started (unless running headless), requests may fail with:
- `503 { "error": "Server is not started..." }`

So your client should treat **503** as “enable/start server first”.

---

# Quickstart Flows

## Flow A: Health check (settings)
**GET** `/settings`

Use this to confirm:
- server is reachable
- auth is correct
- server is started (not returning 503)

## Flow B: Open a project + create a task + run a prompt

### 1) Open the project
**POST** `/project/add-open`

Body:
```
json
{ "projectDir": "/absolute/path/to/project" }
```
### 2) Create a task
**POST** `/project/tasks/new`

Body:
```
json
{
"projectDir": "/absolute/path/to/project",
"parentId": null,
"name": "Optional task name"
}
```
Response includes a task object with an `id` you’ll use next.

### 3) (Optional) Update task settings (models, autoApprove, etc.)
**POST** `/project/tasks`

Body:
```
json
{
"projectDir": "/absolute/path/to/project",
"id": "<TASK_ID>",
"updates": {
"mainModel": "ollama/llama3.1:8b",
"architectModel": "ollama/llama3.1:8b",
"provider": "ollama",
"autoApprove": true
}
}
```
### 4) Run a prompt
**POST** `/run-prompt`

Body:
```
json
{
"projectDir": "/absolute/path/to/project",
"taskId": "<TASK_ID>",
"prompt": "Do something useful…",
"mode": "code"
}
```
### 5) Poll for messages / task state
**POST** `/project/tasks/load`

Body:
```
json
{ "projectDir": "/absolute/path/to/project", "id": "<TASK_ID>" }
```
Your client can poll every few seconds and watch `messages` for completion markers.

---

# Endpoint Catalog (Friendly)

## Settings & App Info

- **GET** `/settings` — read settings (also good for health check)
- **POST** `/settings` — save settings
- **GET** `/settings/recent-projects` — list recent projects
- **POST** `/settings/add-recent-project` — add recent project
- **POST** `/settings/remove-recent-project` — remove recent project
- **POST** `/settings/zoom` — set UI zoom
- **GET** `/versions` — get version info
- **POST** `/download-latest` — trigger “download latest”
- **GET** `/release-notes` — read release notes
- **POST** `/clear-release-notes` — clear release notes
- **GET** `/os` — get OS info

## Projects & Tasks

- **GET** `/projects` — list open projects
- **POST** `/project/add-open` — open a project directory
- **POST** `/project/remove-open` — remove from open projects list
- **POST** `/project/set-active` — set active project
- **POST** `/project/update-order` — reorder open projects
- **POST** `/project/restart` — restart project
- **POST** `/project/start` — start project
- **POST** `/project/stop` — stop project

### Tasks
- **POST** `/project/tasks/new` — create new task
- **GET** `/project/tasks` — list tasks
- **POST** `/project/tasks` — update/save task
- **POST** `/project/tasks/load` — load task + messages
- **POST** `/project/tasks/delete` — delete task
- **POST** `/project/tasks/duplicate` — duplicate task
- **POST** `/project/tasks/fork` — fork task from message
- **POST** `/project/tasks/reset` — reset task
- **POST** `/project/tasks/export-markdown` — export session as markdown download

### Conversation tools
- **POST** `/project/interrupt` — interrupt current response
- **POST** `/project/clear-context` — clear context
- **POST** `/project/answer-question` — submit answer to a question
- **POST** `/project/compact-conversation` — compact history
- **POST** `/project/handoff-conversation` — handoff conversation
- **POST** `/project/remove-last-message` — remove last message
- **DELETE** `/project/remove-message` — remove specific message
- **DELETE** `/project/remove-messages-up-to` — remove messages up to messageId
- **POST** `/project/redo-prompt` — redo last user prompt
- **POST** `/project/resume-task` — resume a task

### File & command helpers
- **POST** `/project/validate-path` — validate a path within a project
- **POST** `/project/is-project-path` — check if a path is a project path
- **POST** `/project/file-suggestions` — get path suggestions
- **POST** `/project/paste-image` — attach pasted image (base64)
- **POST** `/project/apply-edits` — apply file edits
- **POST** `/project/run-command` — run a command
- **POST** `/project/init-rules` — initialize project rules file
- **POST** `/project/scrape-web` — scrape URL and add to context

### Worktree / Git integration
- **POST** `/project/worktree/merge-to-main`
- **POST** `/project/worktree/apply-uncommitted`
- **POST** `/project/worktree/revert-last-merge`
- **GET** `/project/worktree/branches`
- **GET** `/project/worktree/status`
- **POST** `/project/worktree/rebase-from-branch`
- **POST** `/project/worktree/abort-rebase`
- **POST** `/project/worktree/continue-rebase`
- **POST** `/project/worktree/resolve-conflicts-with-agent`

## Prompts
- **POST** `/run-prompt` — run prompt on task
- **POST** `/save-prompt` — save prompt

## Context (task context files)
- **POST** `/add-context-file`
- **POST** `/drop-context-file`
- **POST** `/get-context-files`
- **POST** `/get-addable-files`
- **POST** `/get-all-files`

## Custom commands
- **GET** `/project/custom-commands`
- **POST** `/project/custom-commands`

## Todo
- **GET** `/project/todos`
- **POST** `/project/todo/add`
- **PATCH** `/project/todo/update`
- **POST** `/project/todo/delete`
- **POST** `/project/todo/clear`

## Providers & Models
- **GET** `/providers`
- **POST** `/providers`
- **GET** `/models`
- **PUT** `/models`
- **PUT** `/providers/:providerId/models`
- **DELETE** `/providers/:providerId/models`

## Agent profiles
- **GET** `/agent-profiles`
- **POST** `/agent-profile/create`
- **POST** `/agent-profile/update`
- **POST** `/agent-profile/delete`
- **POST** `/agent-profiles/order`

## MCP
- **POST** `/mcp/tools`
- **POST** `/mcp/reload`

## System
- **GET** `/system/env-var`

## Usage
- **GET** `/usage`

---

# TODO (Known missing enumerations)
These modules are registered and expose additional endpoints, but are not fully enumerated here yet:
- Memory endpoints: `src/main/server/rest-api/memory-api.ts`
- Voice endpoints: `src/main/server/rest-api/voice-api.ts`
- Terminal endpoints: `src/main/server/rest-api/terminal-api.ts`
- BMAD endpoints: `src/main/server/rest-api/bmad-api.ts`

Also, `ProjectApi` may contain additional routes beyond what’s captured here.
```


```markdown
# AiderDesk REST API — Schema-Accurate Reference

This reference focuses on **request validation shapes**:
- HTTP method + path
- query vs body inputs
- required vs optional fields
- enum values

Base URL:
- `http://localhost:24337/api`

Auth:
- Optional/conditional HTTP Basic Auth.

---

## SettingsApi

### GET `/settings`
- Input: none
- Output: settings object (implementation-defined)

### POST `/settings`
- Body: `any` (saved as settings)
- Output: updated settings object

### GET `/settings/recent-projects`
- Query: `{}` (no fields)
- Output: recent projects list

### POST `/settings/add-recent-project`
- Body:
  ```json
  { "projectDir": "string (min 1)" }
  ```
- Output: `{ "message": "Recent project added" }`

### POST `/settings/remove-recent-project`
- Body:
  ```json
  { "projectDir": "string (min 1)" }
  ```
- Output: `{ "message": "Recent project removed" }`

### POST `/settings/zoom`
- Body:
  ```json
  { "level": "number (0.5..3.0 step 0.1)" }
  ```
- Output: `{ "message": "Zoom level set" }`

### GET `/versions`
- Query:
  ```json
  { "forceRefresh": "string (optional, expected 'true' to force refresh)" }
  ```

### POST `/download-latest`
- Body: `{}`
- Output: `{ "message": "Download started" }`

### GET `/release-notes`
- Query: `{}`
- Output: `{ "releaseNotes": "string | null | ... (implementation-defined)" }`

### POST `/clear-release-notes`
- Body: `{}`
- Output: `{ "message": "Release notes cleared" }`

### GET `/os`
- Query: `{}`
- Output: `{ "os": "..." }`

---

## PromptApi

### POST `/run-prompt`
- Body:
  ```json
  {
    "projectDir": "string (min 1)",
    "taskId": "string (min 1)",
    "prompt": "string (min 1)",
    "mode": "agent|code|ask|architect|context (optional)"
  }
  ```
- Output: `responses` (implementation-defined array/object)

### POST `/save-prompt`
- Body:
  ```json
  {
    "projectDir": "string (min 1)",
    "taskId": "string (min 1)",
    "prompt": "string (min 1)"
  }
  ```
- Output: `{ "message": "Prompt saved successfully" }`

---

## ContextApi

### POST `/add-context-file`
- Body:
  ```json
  {
    "projectDir": "string (min 1)",
    "taskId": "string (min 1)",
    "path": "string (min 1)",
    "readOnly": "boolean (optional)"
  }
  ```

### POST `/drop-context-file`
- Body:
  ```json
  {
    "projectDir": "string (min 1)",
    "taskId": "string (min 1)",
    "path": "string (min 1)"
  }
  ```

### POST `/get-context-files`
- Body:
  ```json
  { "projectDir": "string (min 1)", "taskId": "string (min 1)" }
  ```

### POST `/get-addable-files`
- Body:
  ```json
  {
    "projectDir": "string (min 1)",
    "taskId": "string (min 1)",
    "searchRegex": "string (optional)"
  }
  ```

### POST `/get-all-files`
- Body:
  ```json
  {
    "projectDir": "string (min 1)",
    "taskId": "string (min 1)",
    "useGit": "boolean (optional)"
  }
  ```

---

## CommandsApi

### GET `/project/custom-commands`
- Query:
  ```json
  { "projectDir": "string (min 1)" }
  ```

### POST `/project/custom-commands`
- Body:
  ```json
  {
    "projectDir": "string (min 1)",
    "taskId": "string (min 1)",
    "commandName": "string (min 1)",
    "args": ["string", "..."],
    "mode": "code|ask|architect|context|agent"
  }
  ```

---

## UsageApi

### GET `/usage`
- Query:
  ```json
  {
    "from": "string (min 1, parseable date)",
    "to": "string (min 1, parseable date)"
  }
  ```

---

## SystemApi

### GET `/system/env-var`
- Query:
  ```json
  { "key": "string (min 1)", "baseDir": "string (optional)" }
  ```

---

## TodoApi

### GET `/project/todos`
- Query:
  ```json
  { "projectDir": "string (min 1)", "taskId": "string (min 1)" }
  ```

### POST `/project/todo/add`
- Body:
  ```json
  { "projectDir": "string (min 1)", "taskId": "string (min 1)", "name": "string (min 1)" }
  ```

### PATCH `/project/todo/update`
- Body:
  ```json
  {
    "projectDir": "string (min 1)",
    "taskId": "string (min 1)",
    "name": "string (min 1)",
    "updates": {
      "name": "string (optional)",
      "completed": "boolean (optional)"
    }
  }
  ```

### POST `/project/todo/delete`
- Body:
  ```json
  { "projectDir": "string (min 1)", "taskId": "string (min 1)", "name": "string (min 1)" }
  ```

### POST `/project/todo/clear`
- Body:
  ```json
  { "projectDir": "string (min 1)", "taskId": "string (min 1)" }
  ```

---

## McpApi

### POST `/mcp/tools`
- Body:
  ```json
  {
    "serverName": "string (min 1)",
    "config": {
      "command": "string (optional)",
      "args": ["string", "..."] ,
      "env": { "<key>": "string", "...": "string" },
      "url": "string (optional)",
      "headers": { "<key>": "string", "...": "string" }
    }
  }
  ```
  `config` is optional; all inner fields are optional.

### POST `/mcp/reload`
- Body:
  ```json
  {
    "mcpServers": {
      "<serverName>": {
        "command": "string (optional)",
        "args": ["string", "..."] ,
        "env": { "<key>": "string" },
        "url": "string (optional)",
        "headers": { "<key>": "string" }
      }
    },
    "force": "boolean (optional)"
  }
  ```

---

## ProvidersApi

### GET `/providers`
- Input: none

### POST `/providers`
- Body: `array<any>` (provider profiles; currently validated as `any`)
  ```json
  [ { "...": "..." } ]
  ```

### GET `/models`
- Query: `reload=true|false` (optional, string)
    - In practice: `?reload=true` triggers reload

### PUT `/models`
- Body:
  ```json
  [
    {
      "providerId": "string",
      "modelId": "string",
      "model": "any"
    }
  ]
  ```

### PUT `/providers/:providerId/models`
- Params: `{ providerId: string }`
- Query: `{ modelId: string (required) }`
- Body: model payload (not zod-validated here)

### DELETE `/providers/:providerId/models`
- Params: `{ providerId: string }`
- Query: `{ modelId: string (required) }`

---

## AgentApi

### GET `/agent-profiles`
- Input: none

### POST `/agent-profile/create`
- Body:
  ```json
  { "profile": "any", "projectDir": "string (optional)" }
  ```

### POST `/agent-profile/update`
- Body:
  ```json
  { "profile": "any", "baseDir": "string (optional)" }
  ```
  Note: current implementation parses `baseDir` but may not use it downstream.

### POST `/agent-profile/delete`
- Body:
  ```json
  { "profileId": "string (min 1)", "baseDir": "string (optional)" }
  ```

### POST `/agent-profiles/order`
- Body:
  ```json
  { "agentProfiles": ["any", "..."] }
  ```

---

## ProjectApi (partial; schema-accurate for captured routes)

### GET `/projects`
- Input: none

### GET `/project/input-history`
- Query: `{ "projectDir": "string (min 1)" }`

### POST `/project/redo-prompt`
- Body:
  ```json
  {
    "projectDir": "string (min 1)",
    "taskId": "string (min 1)",
    "mode": "agent|code|ask|architect|context",
    "updatedPrompt": "string (optional)"
  }
  ```

### POST `/project/resume-task`
- Body: `{ "projectDir": "string (min 1)", "taskId": "string (min 1)" }`

### POST `/project/validate-path`
- Body: `{ "projectDir": "string (min 1)", "path": "string (min 1)" }`

### POST `/project/is-project-path`
- Body: `{ "path": "string (min 1)" }`

### POST `/project/file-suggestions`
- Body:
  ```json
  { "currentPath": "string (min 1)", "directoriesOnly": "boolean (optional)" }
  ```

### POST `/project/paste-image`
- Body:
  ```json
  {
    "projectDir": "string (min 1)",
    "taskId": "string (min 1)",
    "base64ImageData": "string (optional)"
  }
  ```

### POST `/project/apply-edits`
- Body:
  ```json
  {
    "projectDir": "string (min 1)",
    "taskId": "string (min 1)",
    "edits": [
      { "path": "string", "original": "string", "updated": "string" }
    ]
  }
  ```

### POST `/project/run-command`
- Body:
  ```json
  { "projectDir": "string (min 1)", "taskId": "string (min 1)", "command": "string (min 1)" }
  ```

### POST `/project/init-rules`
- Body: `{ "projectDir": "string (min 1)", "taskId": "string (min 1)" }`

### POST `/project/tasks/new`
- Body:
  ```json
  {
    "projectDir": "string (min 1)",
    "parentId": "string|null (optional)",
    "name": "string (optional)"
  }
  ```

### POST `/project/tasks`
- Body:
  ```json
  {
    "projectDir": "string (min 1)",
    "id": "string (min 1)",
    "updates": "partial TaskData (schema from shared types)"
  }
  ```

### POST `/project/tasks/load`
- Body: `{ "projectDir": "string (min 1)", "id": "string (min 1)" }`

### GET `/project/tasks`
- Query: `{ "projectDir": "string (min 1)" }`

### POST `/project/tasks/delete`
- Body: `{ "projectDir": "string (min 1)", "id": "string (min 1)" }`

### POST `/project/tasks/duplicate`
- Body: `{ "projectDir": "string (min 1)", "taskId": "string (min 1)" }`

### POST `/project/tasks/fork`
- Body:
  ```json
  {
    "projectDir": "string (min 1)",
    "taskId": "string (min 1)",
    "messageId": "string (min 1)"
  }
  ```

### POST `/project/tasks/reset`
- Body: `{ "projectDir": "string (min 1)", "taskId": "string (min 1)" }`

### POST `/project/tasks/export-markdown`
- Body: `{ "projectDir": "string (min 1)", "taskId": "string (min 1)" }`

### POST `/project/remove-last-message`
- Body: `{ "projectDir": "string (min 1)", "taskId": "string (min 1)" }`

### DELETE `/project/remove-message`
- Body:
  ```json
  {
    "projectDir": "string (min 1)",
    "taskId": "string (min 1)",
    "messageId": "string (min 1)"
  }
  ```

### DELETE `/project/remove-messages-up-to`
- Body:
  ```json
  {
    "projectDir": "string (min 1)",
    "taskId": "string (min 1)",
    "messageId": "string (min 1)"
  }
  ```

### POST `/project/compact-conversation`
- Body:
  ```json
  {
    "projectDir": "string (min 1)",
    "taskId": "string (min 1)",
    "mode": "agent|code|ask|architect|context",
    "customInstructions": "string (optional)"
  }
  ```

### POST `/project/handoff-conversation`
- Body:
  ```json
  { "projectDir": "string (min 1)", "taskId": "string (min 1)", "focus": "string (optional)" }
  ```

### POST `/project/scrape-web`
- Body:
  ```json
  {
    "projectDir": "string (min 1)",
    "taskId": "string (min 1)",
    "url": "string (valid URL, min 1)",
    "filePath": "string (optional)"
  }
  ```

### Worktree endpoints
- **POST** `/project/worktree/merge-to-main`
  ```json
  { "projectDir": "string (min 1)", "taskId": "string (min 1)", "squash": "boolean", "targetBranch": "string (optional)", "commitMessage": "string (optional)" }
  ```
- **POST** `/project/worktree/apply-uncommitted`
  ```json
  { "projectDir": "string (min 1)", "taskId": "string (min 1)", "targetBranch": "string (optional)" }
  ```
- **POST** `/project/worktree/revert-last-merge`
  ```json
  { "projectDir": "string (min 1)", "taskId": "string (min 1)" }
  ```
- **GET** `/project/worktree/branches`
    - Query: `{ "projectDir": "string (min 1)" }`
- **GET** `/project/worktree/status`
    - Query:
      ```json
      { "projectDir": "string (min 1)", "taskId": "string (min 1)", "targetBranch": "string (optional)" }
      ```
- **POST** `/project/worktree/rebase-from-branch`
  ```json
  { "projectDir": "string (min 1)", "taskId": "string (min 1)", "fromBranch": "string (optional)" }
  ```
- **POST** `/project/worktree/abort-rebase`
  ```json
  { "projectDir": "string (min 1)", "taskId": "string (min 1)" }
  ```
- **POST** `/project/worktree/continue-rebase`
  ```json
  { "projectDir": "string (min 1)", "taskId": "string (min 1)" }
  ```
- **POST** `/project/worktree/resolve-conflicts-with-agent`
  ```json
  { "projectDir": "string (min 1)", "taskId": "string (min 1)" }
  ```

### Project list management
- **POST** `/project/update-order`
    - Body: `{ "projectDirs": ["string (min 1)", "..."] }`
- **POST** `/project/remove-open`
    - Body: `{ "projectDir": "string (min 1)" }`
- **POST** `/project/set-active`
    - Body: `{ "projectDir": "string (min 1)" }`
- **POST** `/project/restart`
    - Body: `{ "projectDir": "string (min 1)" }`

### Project settings
- **GET** `/project/settings`
    - Query: `{ "projectDir": "string (min 1)" }`
- **PATCH** `/project/settings`
    - Body: `{ "projectDir": "string (min 1)", "...": "partial ProjectSettings fields" }`

### Model helpers (task-scoped)
- **POST** `/project/settings/main-model`
    - Body: `{ "projectDir": "string (min 1)", "taskId": "string (min 1)", "mainModel": "string (min 1)" }`
- **POST** `/project/settings/weak-model`
    - Body: `{ "projectDir": "string (min 1)", "taskId": "string (min 1)", "weakModel": "string (min 1)" }`
- **POST** `/project/settings/architect-model`
    - Body: `{ "projectDir": "string (min 1)", "taskId": "string (min 1)", "architectModel": "string (min 1)" }`
- **POST** `/project/settings/edit-formats`
    - Body:
      ```json
      {
        "projectDir": "string (min 1)",
        "editFormats": { "<key>": "diff|diff-fenced|whole|udiff|udiff-simple|patch" }
      }
      ```

### Lifecycle
- **POST** `/project/start` — Body `{ "projectDir": "string (min 1)" }`
- **POST** `/project/stop` — Body `{ "projectDir": "string (min 1)" }`
- **POST** `/project/add-open` — Body `{ "projectDir": "string (min 1)" }`

### Conversation control
- **POST** `/project/interrupt`
    - Body: `{ "projectDir": "string (min 1)", "taskId": "string (min 1)" }`
- **POST** `/project/clear-context`
    - Body: `{ "projectDir": "string (min 1)", "taskId": "string (min 1)" }`
- **POST** `/project/answer-question`
    - Body: `{ "projectDir": "string (min 1)", "taskId": "string (min 1)", "answer": "string (min 1)" }`

---

# TODO: Remaining schema-accurate modules

The following modules are registered under `/api` and should be added here by extracting their `router.<method>(...)` definitions:

- `src/main/server/rest-api/memory-api.ts`
- `src/main/server/rest-api/voice-api.ts`
- `src/main/server/rest-api/terminal-api.ts`
- `src/main/server/rest-api/bmad-api.ts`

Also verify whether `ProjectApi` contains additional routes further down not yet included in this reference.
```


If you want, I can also add a third optional artifact later: an **OpenAPI-like JSON/YAML** generated from the schema-accurate doc (even if it’s not perfectly OpenAPI-compliant, it’s very handy for SDK generation and contract testing).
