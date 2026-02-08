You’re right — and I did: I created a Markdown document in the previous message.

```markdown
# AiderDesk REST API — cURL Examples (confirmed endpoints)

This document contains `curl` examples for REST endpoints confirmed in the codebase.

## Conventions

- Base URL:
  - `BASE_URL="http://localhost:<PORT>"`
  - API root: `${BASE_URL}/api`
- Most endpoints return JSON.
- Some endpoints require auth depending on settings/environment.

### Optional: Basic Auth

If Basic Auth is enabled, add `-u "<USERNAME>:<PASSWORD>"` to requests.
```
bash
AUTH='-u "admin:booberry"'
```
If auth is not enabled, you can set:
```
bash
AUTH=''
```
### Common placeholders

Set these once in your shell:
```
bash
BASE_URL="http://localhost:<PORT>"
API="${BASE_URL}/api"
PROJECT_DIR="<ABSOLUTE_PATH_TO_PROJECT_DIR>"
TASK_ID="<TASK_ID>"
```
---

## System

### GET /api/system/env-var

Query params:
- `key` (required)
- `baseDir` (optional)
```
bash
curl -sS $AUTH \
"${API}/system/env-var?key=<ENV_VAR_NAME>"
```
With `baseDir`:
```
bash
curl -sS $AUTH \
"${API}/system/env-var?key=<ENV_VAR_NAME>&baseDir=<ABSOLUTE_BASE_DIR>"
```
---

## Settings

### GET /api/settings
```
bash
curl -sS $AUTH \
"${API}/settings"
```
### POST /api/settings

Body: settings object (schema is permissive in code)
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/settings" \
-d @- <<'JSON'
{
"server": {
"enabled": true
}
}
JSON
```
### GET /api/settings/recent-projects
```
bash
curl -sS $AUTH \
"${API}/settings/recent-projects"
```
### POST /api/settings/add-recent-project
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/settings/add-recent-project" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}"
}
JSON
```
### POST /api/settings/remove-recent-project
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/settings/remove-recent-project" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}"
}
JSON
```
### POST /api/settings/zoom

Body:
- `level`: number between 0.5 and 3.0 in steps of 0.1
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/settings/zoom" \
-d @- <<'JSON'
{
"level": 1.0
}
JSON
```
### GET /api/versions

Optional query:
- `forceRefresh=true`
```
bash
curl -sS $AUTH \
"${API}/versions"
```
Force refresh:
```
bash
curl -sS $AUTH \
"${API}/versions?forceRefresh=true"
```
### POST /api/download-latest
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/download-latest" \
-d '{}'
```
### GET /api/release-notes
```
bash
curl -sS $AUTH \
"${API}/release-notes"
```
### POST /api/clear-release-notes
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/clear-release-notes" \
-d '{}'
```
### GET /api/os
```
bash
curl -sS $AUTH \
"${API}/os"
```
---

## Prompt

### POST /api/run-prompt

Body:
- `projectDir` (required)
- `taskId` (required)
- `prompt` (required)
- `mode` (optional): `agent | code | ask | architect | context`
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/run-prompt" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"taskId": "${TASK_ID}",
"prompt": "Hello from curl!",
"mode": "agent"
}
JSON
```
### POST /api/save-prompt
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/save-prompt" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"taskId": "${TASK_ID}",
"prompt": "Save this prompt for later"
}
JSON
```
---

## Context files

### POST /api/add-context-file

Body:
- `projectDir`
- `taskId`
- `path` (file path, project-relative or absolute depending on implementation)
- `readOnly` (optional boolean)
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/add-context-file" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"taskId": "${TASK_ID}",
"path": "<FILE_PATH>",
"readOnly": true
}
JSON
```
### POST /api/drop-context-file
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/drop-context-file" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"taskId": "${TASK_ID}",
"path": "<FILE_PATH>"
}
JSON
```
### POST /api/get-context-files
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/get-context-files" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"taskId": "${TASK_ID}"
}
JSON
```
### POST /api/get-addable-files

Optional field:
- `searchRegex`
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/get-addable-files" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"taskId": "${TASK_ID}",
"searchRegex": ".*\\\\.ts$"
}
JSON
```
### POST /api/get-all-files

Optional field:
- `useGit` (boolean)
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/get-all-files" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"taskId": "${TASK_ID}",
"useGit": true
}
JSON
```
---

## Custom commands

### GET /api/project/custom-commands

Query params:
- `projectDir`
```
bash
curl -sS $AUTH \
"${API}/project/custom-commands?projectDir=<URL_ENCODED_PROJECT_DIR>"
```
### POST /api/project/custom-commands

Body:
- `projectDir`
- `taskId`
- `commandName`
- `args` (array of strings)
- `mode`: `code | ask | architect | context | agent`
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/custom-commands" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"taskId": "${TASK_ID}",
"commandName": "<COMMAND_NAME>",
"args": ["--flag", "value"],
"mode": "agent"
}
JSON
```
---

## Project / tasks / worktrees

### GET /api/projects
```
bash
curl -sS $AUTH \
"${API}/projects"
```
### GET /api/project/input-history

Query:
- `projectDir`
```
bash
curl -sS $AUTH \
"${API}/project/input-history?projectDir=<URL_ENCODED_PROJECT_DIR>"
```
### POST /api/project/redo-prompt

Body:
- `projectDir`
- `taskId`
- `mode`: `agent | code | ask | architect | context`
- `updatedPrompt` (optional)
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/redo-prompt" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"taskId": "${TASK_ID}",
"mode": "agent",
"updatedPrompt": "Redo this prompt with a small change"
}
JSON
```
### POST /api/project/resume-task
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/resume-task" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"taskId": "${TASK_ID}"
}
JSON
```
### POST /api/project/validate-path

Body:
- `projectDir`
- `path`
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/validate-path" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"path": "<PATH_TO_VALIDATE>"
}
JSON
```
### POST /api/project/is-project-path

Body:
- `path`
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/is-project-path" \
-d @- <<'JSON'
{
"path": "<ABSOLUTE_PATH>"
}
JSON
```
### POST /api/project/file-suggestions

Body:
- `currentPath`
- `directoriesOnly` (optional boolean)
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/file-suggestions" \
-d @- <<'JSON'
{
"currentPath": "src/",
"directoriesOnly": false
}
JSON
```
### POST /api/project/paste-image

Body:
- `projectDir`
- `taskId`
- `base64ImageData` (optional string)
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/paste-image" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"taskId": "${TASK_ID}",
"base64ImageData": "<DATA_URI_OR_BASE64>"
}
JSON
```
### POST /api/project/apply-edits

Body:
- `projectDir`
- `taskId`
- `edits`: array of `{ path, original, updated }`
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/apply-edits" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"taskId": "${TASK_ID}",
"edits": [
{
"path": "<FILE_PATH>",
"original": "old text",
"updated": "new text"
}
]
}
JSON
```
### POST /api/project/run-command

Body:
- `projectDir`
- `taskId`
- `command`
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/run-command" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"taskId": "${TASK_ID}",
"command": "ls -la"
}
JSON
```
### POST /api/project/init-rules
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/init-rules" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"taskId": "${TASK_ID}"
}
JSON
```
### POST /api/project/tasks/new

Body:
- `projectDir`
- `parentId` (optional, nullable)
- `name` (optional)
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/tasks/new" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"parentId": null,
"name": "Task created from curl"
}
JSON
```
### POST /api/project/tasks (update/save task)

Body:
- `projectDir`
- `id` (task id)
- `updates` (partial task object)
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/tasks" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"id": "${TASK_ID}",
"updates": {
"name": "Renamed task"
}
}
JSON
```
### POST /api/project/tasks/load

Body:
- `projectDir`
- `id`
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/tasks/load" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"id": "${TASK_ID}"
}
JSON
```
### GET /api/project/tasks

Query:
- `projectDir`
```
bash
curl -sS $AUTH \
"${API}/project/tasks?projectDir=<URL_ENCODED_PROJECT_DIR>"
```
### POST /api/project/tasks/delete
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/tasks/delete" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"id": "${TASK_ID}"
}
JSON
```
### POST /api/project/tasks/duplicate
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/tasks/duplicate" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"taskId": "${TASK_ID}"
}
JSON
```
### POST /api/project/tasks/fork
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/tasks/fork" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"taskId": "${TASK_ID}",
"messageId": "<MESSAGE_ID>"
}
JSON
```
### POST /api/project/tasks/reset
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/tasks/reset" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"taskId": "${TASK_ID}"
}
JSON
```
### POST /api/project/tasks/export-markdown

Returns a Markdown file (sets `Content-Disposition: attachment`).
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/tasks/export-markdown" \
-o "session-export.md" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"taskId": "${TASK_ID}"
}
JSON
```
### POST /api/project/remove-last-message
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/remove-last-message" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"taskId": "${TASK_ID}"
}
JSON
```
### DELETE /api/project/remove-message

Body:
- `projectDir`
- `taskId`
- `messageId`
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X DELETE "${API}/project/remove-message" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"taskId": "${TASK_ID}",
"messageId": "<MESSAGE_ID>"
}
JSON
```
### DELETE /api/project/remove-messages-up-to

Body:
- `projectDir`
- `taskId`
- `messageId`
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X DELETE "${API}/project/remove-messages-up-to" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"taskId": "${TASK_ID}",
"messageId": "<MESSAGE_ID>"
}
JSON
```
### POST /api/project/compact-conversation

Body:
- `projectDir`
- `taskId`
- `mode`
- `customInstructions` (optional)
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/compact-conversation" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"taskId": "${TASK_ID}",
"mode": "agent",
"customInstructions": "Keep it short and focused"
}
JSON
```
### POST /api/project/handoff-conversation

Body:
- `projectDir`
- `taskId`
- `focus` (optional)
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/handoff-conversation" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"taskId": "${TASK_ID}",
"focus": "Summarize current progress and next steps"
}
JSON
```
### POST /api/project/scrape-web

Body:
- `projectDir`
- `taskId`
- `url` (required)
- `filePath` (optional)
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/scrape-web" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"taskId": "${TASK_ID}",
"url": "https://example.com",
"filePath": "docs/scraped/example.md"
}
JSON
```
### POST /api/project/worktree/merge-to-main

Body:
- `projectDir`
- `taskId`
- `squash` (boolean)
- `targetBranch` (optional)
- `commitMessage` (optional)
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/worktree/merge-to-main" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"taskId": "${TASK_ID}",
"squash": true,
"targetBranch": "main",
"commitMessage": "Merge worktree changes"
}
JSON
```
### POST /api/project/worktree/apply-uncommitted

Body:
- `projectDir`
- `taskId`
- `targetBranch` (optional)
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/worktree/apply-uncommitted" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"taskId": "${TASK_ID}",
"targetBranch": "main"
}
JSON
```
### POST /api/project/worktree/revert-last-merge
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/worktree/revert-last-merge" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"taskId": "${TASK_ID}"
}
JSON
```
### GET /api/project/worktree/branches

Query:
- `projectDir`
```
bash
curl -sS $AUTH \
"${API}/project/worktree/branches?projectDir=<URL_ENCODED_PROJECT_DIR>"
```
### GET /api/project/worktree/status

Query:
- `projectDir`
- `taskId`
- `targetBranch` (optional)
```
bash
curl -sS $AUTH \
"${API}/project/worktree/status?projectDir=<URL_ENCODED_PROJECT_DIR>&taskId=<TASK_ID>&targetBranch=main"
```
### POST /api/project/worktree/rebase-from-branch

Body:
- `projectDir`
- `taskId`
- `fromBranch` (optional)
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/worktree/rebase-from-branch" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"taskId": "${TASK_ID}",
"fromBranch": "main"
}
JSON
```
### POST /api/project/worktree/abort-rebase
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/worktree/abort-rebase" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"taskId": "${TASK_ID}"
}
JSON
```
### POST /api/project/worktree/continue-rebase
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/worktree/continue-rebase" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"taskId": "${TASK_ID}"
}
JSON
```
### POST /api/project/worktree/resolve-conflicts-with-agent
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/worktree/resolve-conflicts-with-agent" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"taskId": "${TASK_ID}"
}
JSON
```
### POST /api/project/update-order

Body:
- `projectDirs` (array)
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/update-order" \
-d @- <<JSON
{
"projectDirs": ["${PROJECT_DIR}", "<ANOTHER_PROJECT_DIR>"]
}
JSON
```
### POST /api/project/remove-open
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/remove-open" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}"
}
JSON
```
### POST /api/project/set-active
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/set-active" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}"
}
JSON
```
### POST /api/project/restart
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/restart" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}"
}
JSON
```
### GET /api/project/settings

Query:
- `projectDir`
```
bash
curl -sS $AUTH \
"${API}/project/settings?projectDir=<URL_ENCODED_PROJECT_DIR>"
```
### PATCH /api/project/settings

Body: partial project settings + `projectDir`
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X PATCH "${API}/project/settings" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"someSetting": "someValue"
}
JSON
```
### POST /api/project/interrupt
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/interrupt" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"taskId": "${TASK_ID}"
}
JSON
```
### POST /api/project/clear-context
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/clear-context" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"taskId": "${TASK_ID}"
}
JSON
```
### POST /api/project/answer-question

Body:
- `projectDir`
- `taskId`
- `answer`
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/answer-question" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"taskId": "${TASK_ID}",
"answer": "Yes, proceed."
}
JSON
```
### POST /api/project/settings/main-model

Body:
- `projectDir`
- `taskId`
- `mainModel`
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/settings/main-model" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"taskId": "${TASK_ID}",
"mainModel": "<MODEL_ID>"
}
JSON
```
### POST /api/project/settings/weak-model
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/settings/weak-model" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"taskId": "${TASK_ID}",
"weakModel": "<MODEL_ID>"
}
JSON
```
### POST /api/project/settings/architect-model
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/settings/architect-model" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"taskId": "${TASK_ID}",
"architectModel": "<MODEL_ID>"
}
JSON
```
### POST /api/project/settings/edit-formats

Body:
- `projectDir`
- `editFormats`: map of string -> enum(`diff`, `diff-fenced`, `whole`, `udiff`, `udiff-simple`, `patch`)
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/settings/edit-formats" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}",
"editFormats": {
"typescript": "diff"
}
}
JSON
```
### POST /api/project/start
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/start" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}"
}
JSON
```
### POST /api/project/stop
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/stop" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}"
}
JSON
```
### POST /api/project/add-open
```
bash
curl -sS $AUTH \
-H "Content-Type: application/json" \
-X POST "${API}/project/add-open" \
-d @- <<JSON
{
"projectDir": "${PROJECT_DIR}"
}
JSON
```

```


If you’d like, I can revise the few `GET ...?projectDir=...` examples to include a clean macOS-friendly URL-encoding one-liner (so you don’t have to manually replace `<URL_ENCODED_PROJECT_DIR>`).