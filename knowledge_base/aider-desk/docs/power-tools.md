# AiderDesk Power Tools & MCP Servers Reference

> **Audience**: Senior developers using AiderDesk via the UI
> **Last updated**: 2026-02-11

---

## Overview

AiderDesk's Agent mode provides a comprehensive toolkit for autonomous development work. This document covers the **Power Tools** (built-in file and system operations), **Aider Tools** (delegating to Aider for code generation), **Task Tools** (multi-task management), **Todo Tools** (task planning), **Memory Tools** (persistent knowledge), and **MCP Servers** (extensibility via Model Context Protocol).

All tools are organized into **tool groups** and can be enabled/disabled per **Agent Profile**. Each tool has configurable **approval settings** to control automation vs. manual oversight.

---

## Table of Contents

1. [Agent Profiles](#agent-profiles)
2. [Power Tools](#power-tools)
3. [Aider Tools](#aider-tools)
4. [Task Tools](#task-tools)
5. [Todo Tools](#todo-tools)
6. [Memory Tools](#memory-tools)
7. [Repository Map](#repository-map)
8. [MCP Servers](#mcp-servers)
9. [Tool Approval System](#tool-approval-system)
10. [API Reference](#api-reference)

---

## Agent Profiles

Agent Profiles are the core configuration mechanism for controlling agent behavior. Each profile defines:

- **Which tool groups are enabled** (Power Tools, Aider Tools, Task Tools, etc.)
- **Approval settings** for each individual tool
- **Context settings** (include context files, repository map)
- **Model configuration** (provider, model name, temperature, max iterations)
- **Custom instructions** and rule files
- **MCP server integrations**
- **Subagent configuration** (optional)

### Pre-Configured Profiles

AiderDesk ships with three default profiles:

| Profile | Tools Enabled | Repository Map | Best For |
|---------|---------------|----------------|----------|
| **Power Tools** | Power Tools only | ❌ | Direct file manipulation, analysis, search |
| **Aider** | Aider Tools only | ✅ | AI-powered code generation and refactoring |
| **Aider with Power Search** | Aider Tools + Power Tools (search only) | ✅ | Combining search with code generation |

### Profile Storage

Profiles are stored as **file-based configurations**:

- **Global**: `~/.aider-desk/agents/<profile-name>/config.json`
- **Project-specific**: `<projectDir>/.aider-desk/agents/<profile-name>/config.json`

Each profile directory can contain:
- `config.json` — Profile settings
- `rules/` — Optional markdown files with additional instructions

Project profiles override global profiles with the same ID.

### Profile Configuration via UI

Access profile settings via **Settings → Agent**:

1. Select or create a profile
2. Configure tool groups (toggles for Power Tools, Aider Tools, etc.)
3. Set individual tool approvals (Always, Ask, Never)
4. Add custom instructions or rule files
5. Select enabled MCP servers
6. Configure subagent settings (if applicable)

---

## Power Tools

**Power Tools** provide direct file system and environment access for the agent. They are fast, targeted operations ideal for:

- File reading, writing, and editing
- Pattern-based search (glob, grep, semantic search)
- Shell command execution
- Web content fetching

### Available Power Tools

#### `power---file_read`

**Description**: Reads non-binary file content with optional line numbers and range control.

**Parameters**:
- `filePath` (string): Relative to working directory or absolute
- `withLines` (boolean, optional): Return content with line numbers (format: `lineNumber|content`)
- `lineOffset` (number, optional): Starting line (0-based), default: 0
- `lineLimit` (number, optional): Max lines to read, default: 1000

**Use Cases**:
- Inspecting configuration files
- Reviewing code before modifications
- Understanding file structure

**Example**:
```json
{
  "filePath": "src/components/UserProfile.tsx",
  "withLines": true,
  "lineOffset": 0,
  "lineLimit": 50
}
```

---

#### `power---file_write`

**Description**: Writes content to a file with three modes: create-only, overwrite, or append.

**Parameters**:
- `filePath` (string): Relative to working directory
- `content` (string): Content to write
- `mode` (enum): `create_only` | `overwrite` | `append`, default: `create_only`

**Use Cases**:
- Creating new components
- Adding configuration files
- Appending to logs

**Example**:
```json
{
  "filePath": "src/components/NewComponent.tsx",
  "content": "import React from 'react';\n\nexport const NewComponent = () => {\n  return <div>Hello</div>;\n};",
  "mode": "create_only"
}
```

---

#### `power---file_edit`

**Description**: Atomically find and replace content in a file. Supports regex and multi-line replacements.

**Parameters**:
- `filePath` (string): Relative to working directory
- `searchTerm` (string): Exact content to find (or regex if `isRegex: true`)
- `replacementText` (string): Replacement content
- `isRegex` (boolean, optional): Treat `searchTerm` as regex, default: false
- `replaceAll` (boolean, optional): Replace all occurrences, default: false

**Use Cases**:
- Renaming variables or functions
- Updating configuration values
- Refactoring code patterns

**Example**:
```json
{
  "filePath": "src/utils.ts",
  "searchTerm": "const oldFunctionName = () => {",
  "replacementText": "const newFunctionName = () => {",
  "replaceAll": false
}
```

---

#### `power---glob`

**Description**: Finds files matching glob patterns (wildcards).

**Parameters**:
- `pattern` (string): Glob pattern (e.g., `**/*.ts`, `src/**/*.tsx`)
- `cwd` (string, optional): Working directory, default: project root
- `ignore` (array of strings, optional): Patterns to exclude

**Use Cases**:
- Listing files by type
- Finding configuration files
- Project structure discovery

**Example**:
```json
{
  "pattern": "src/**/*.test.ts",
  "ignore": ["node_modules/**", "dist/**"]
}
```

---

#### `power---grep`

**Description**: Searches file content using regex with context lines.

**Parameters**:
- `filePattern` (string): Glob pattern for files to search
- `searchTerm` (string): Regex pattern to match
- `contextLines` (number, optional): Lines of context before/after, default: 0
- `caseSensitive` (boolean, optional): Case-sensitive search, default: false
- `maxResults` (number, optional): Max results to return, default: 50

**Use Cases**:
- Finding function calls
- Locating TODO comments
- Searching error messages

**Example**:
```json
{
  "filePattern": "src/**/*.ts",
  "searchTerm": "console\\.log",
  "contextLines": 2,
  "maxResults": 20
}
```

---

#### `power---semantic_search`

**Description**: Semantic code search using natural language queries powered by the Probe search engine.

**Parameters**:
- `query` (string): Natural language search query (2-5 descriptive words)
- `path` (string, optional): Absolute path or dependency (e.g., `go:github.com/owner/repo`)
- `allowTests` (boolean, optional): Include test files, default: false
- `exact` (boolean, optional): Exact search without tokenization, default: false
- `maxTokens` (number, optional): Max tokens in results, default: 5000
- `language` (string, optional): Filter by language (ts, js, py, go, etc.)

**Use Cases**:
- Finding functions by description
- Understanding codebase architecture
- Locating similar code patterns

**Example**:
```json
{
  "query": "authentication user login flow",
  "allowTests": false,
  "maxTokens": 5000,
  "language": "typescript"
}
```

---

#### `power---bash`

**Description**: Executes shell commands with safety controls and approval.

**Parameters**:
- `command` (string): Shell command to execute
- `cwd` (string, optional): Working directory, default: project root
- `timeout` (number, optional): Timeout in ms, default: 120000 (2 min)

**Returns**:
```json
{
  "stdout": "command output",
  "stderr": "error output",
  "exitCode": 0
}
```

**Use Cases**:
- Running tests
- Installing dependencies
- Git operations
- Build scripts

**Security**: Supports allowed/denied pattern filtering via profile settings.

**Example**:
```json
{
  "command": "npm test",
  "timeout": 300000
}
```

---

#### `power---fetch`

**Description**: Fetches web content via HTTP/HTTPS.

**Parameters**:
- `url` (string): URL to fetch
- `timeout` (number, optional): Timeout in ms, default: 60000
- `format` (enum, optional): `markdown` | `html` | `raw`, default: `markdown`

**Use Cases**:
- Fetching documentation
- Reading API responses
- Retrieving external resources

**Example**:
```json
{
  "url": "https://docs.example.com/api",
  "format": "markdown"
}
```

---

### Power Tools Configuration

**Enable Power Tools**: Settings → Agent → Profile → Toggle "Use Power Tools"

**Tool-Specific Settings**:
- **Bash tool**: Configure `allowedPattern` and `deniedPattern` (regex, semicolon-separated)

**Default Approval States**:
- `file_read`: Always
- `file_write`: Ask
- `file_edit`: Ask
- `glob`: Always
- `grep`: Always
- `semantic_search`: Always
- `bash`: Ask (with pattern filtering)
- `fetch`: Always

---

## Aider Tools

**Aider Tools** delegate code generation and refactoring to Aider's underlying engine. The agent can add/drop files from Aider's context and run prompts that generate diffs.

### Available Aider Tools

#### `aider---get_context_files`

**Description**: Retrieves the list of files currently in Aider's context.

**Returns**: Array of file paths with read-only status.

---

#### `aider---add_context_files`

**Description**: Adds files to Aider's context for reading or editing.

**Parameters**:
- `paths` (array of strings): File paths (relative or absolute)
- `readOnly` (boolean, optional): Mark files as read-only, default: false

**Behavior**: If file doesn't exist, prompts to create it.

---

#### `aider---drop_context_files`

**Description**: Removes files from Aider's context.

**Parameters**:
- `paths` (array of strings): File paths to remove

---

#### `aider---run_prompt`

**Description**: Sends a natural language prompt to Aider for code generation/modification.

**Parameters**:
- `prompt` (string): Natural language coding task (language-agnostic)

**Returns**:
```json
{
  "responses": [...],
  "updatedFiles": ["file1.ts", "file2.ts"],
  "promptContext": {...}
}
```

**Key Requirements**:
- All relevant files must be in Aider context **before** calling this tool
- Prompts must be language-agnostic (no mention of Python, JavaScript, etc.)
- Aider applies changes as diffs (configured edit format: `diff`, `udiff`, `whole`, etc.)

---

### Aider Tools Configuration

**Enable Aider Tools**: Settings → Agent → Profile → Toggle "Use Aider Tools"

**Include Repository Map**: Toggle "Include Repository Map" to give Aider a high-level codebase overview.

**Default Approval States**:
- `get_context_files`: Always
- `add_context_files`: Always
- `drop_context_files`: Always
- `run_prompt`: Ask

---

## Task Tools

**Task Tools** enable agents to create, manage, and search across multiple tasks within a project. Tasks are isolated workspaces with their own context files, messages, and agent profiles.

### Available Task Tools

#### `tasks---list_tasks`

**Description**: Lists all tasks in the project.

**Parameters**:
- `offset` (number, optional): Pagination offset
- `limit` (number, optional): Max tasks to return
- `state` (string, optional): Filter by state (e.g., TODO, IN_PROGRESS, DONE)

**Returns**: Array of task summaries with subtask IDs.

---

#### `tasks---get_task`

**Description**: Gets comprehensive details about a specific task.

**Parameters**:
- `taskId` (string): Task ID

**Returns**: Task metadata, context files, message count, agent profile, subtask IDs.

---

#### `tasks---get_task_message`

**Description**: Retrieves a specific message from a task's conversation history.

**Parameters**:
- `taskId` (string): Task ID
- `messageIndex` (number): 0-based index (negative indexes count from end: -1 = last)

**Returns**: Message content, role, usage report.

---

#### `tasks---create_task`

**Description**: Creates a new task (optionally as a subtask of the current task).

**Parameters**:
- `prompt` (string): Initial prompt
- `name` (string, optional): Task name (auto-generated if omitted and `autoGenerateTaskName` is enabled)
- `agentProfileId` (string, optional): Agent profile to use
- `modelId` (string, optional): Model override (format: `provider/model`)
- `execute` (boolean, optional): Execute prompt immediately, default: false
- `executeInBackground` (boolean, optional): Run in background, default: false
- `parentTaskId` (string, optional): Parent task ID (only for top-level tasks)

**Note**: Subtasks cannot create subtasks (only top-level tasks can specify `parentTaskId`).

---

#### `tasks---delete_task`

**Description**: Permanently deletes a task (cannot delete current task).

**Parameters**:
- `taskId` (string): Task ID

---

#### `tasks---search_task`

**Description**: Semantic search within a task's conversation and context files.

**Parameters**:
- `taskId` (string): Task ID
- `query` (string): Natural language query
- `maxTokens` (number, optional): Max tokens in results, default: 10000

---

#### `tasks---search_parent_task`

**Description**: (Subtasks only) Searches parent task conversation and context.

**Parameters**:
- `query` (string): Natural language query
- `maxTokens` (number, optional): Max tokens in results, default: 10000

---

### Task Tools Configuration

**Enable Task Tools**: Settings → Agent → Profile → Toggle "Use Task Tools"

**Default Approval States**:
- `list_tasks`: Always
- `get_task`: Always
- `get_task_message`: Always
- `create_task`: Ask
- `delete_task`: Ask
- `search_task` / `search_parent_task`: Always

---

## Todo Tools

**Todo Tools** enable agents to manage a persistent to-do list for task planning and progress tracking.

### Available Todo Tools

#### `todo---set_items`

**Description**: Initializes or overwrites the to-do list.

**Parameters**:
- `items` (array): Array of `{ name: string, completed: boolean }`
- `initialUserPrompt` (string): Original user request for context

---

#### `todo---get_items`

**Description**: Retrieves current to-do list.

**Returns**: `{ initialUserPrompt: string, items: [...] }`

---

#### `todo---update_item_completion`

**Description**: Updates completion status of a to-do item by name.

**Parameters**:
- `name` (string): To-do item name
- `completed` (boolean): New completion status

---

#### `todo---clear_items`

**Description**: Clears all to-do items.

---

### Todo Tools Configuration

**Enable Todo Tools**: Settings → Agent → Profile → Toggle "Use Todo Tools"

**Default Approval States**:
- `set_items`: Ask
- `get_items`: Always
- `update_item_completion`: Ask
- `clear_items`: Ask

---

## Memory Tools

**Memory Tools** provide persistent, project-scoped knowledge storage using a local vector database (LanceDB). Agents can store, retrieve, update, and delete memories.

### Available Memory Tools

#### `memory---store_memory`

**Description**: Stores information in memory.

**Parameters**:
- `type` (enum): `task` | `user-preference` | `code-pattern`
- `content` (string): Memory content

---

#### `memory---retrieve_memory`

**Description**: Semantic search across stored memories.

**Parameters**:
- `query` (string): Search query (3-7 descriptive words)
- `limit` (number, optional): Max memories to return, default: 3

**Query Best Practices**:
- Use 3-7 descriptive words
- Include key concepts and context
- Describe what you're looking for in natural language
- Example: "LLM provider integration patterns", "Voice control implementation details"

---

#### `memory---list_memories`

**Description**: Lists memories with optional filtering.

**Parameters**:
- `type` (enum, optional): Filter by type
- `limit` (number, optional): Max memories, default: 20

---

#### `memory---update_memory`

**Description**: Updates existing memory content.

**Parameters**:
- `id` (string): Memory ID
- `content` (string): New content

---

#### `memory---delete_memory`

**Description**: Deletes a memory by ID.

**Parameters**:
- `id` (string): Memory ID

---

### Memory Tools Configuration

**Enable Memory Tools**: Settings → Agent → Profile → Toggle "Use Memory Tools"

**Default Approval States**:
- `store_memory`: Always
- `retrieve_memory`: Always
- `list_memories`: Never
- `update_memory`: Never
- `delete_memory`: Never

---

## Repository Map

The **Repository Map** is an Aider-generated high-level overview of the project structure. When enabled in an agent profile, it's included in the agent's system prompt, providing architectural context without loading all file contents.

### What It Includes

- Directory structure
- File relationships
- Key components and modules
- Import/export patterns

### When to Enable

- **Enable** for Aider-based profiles (architectural understanding)
- **Disable** for Power Tools-only profiles (not needed for direct file ops)
- **Enable** for large codebases (helps with navigation)

### Configuration

**Enable Repository Map**: Settings → Agent → Profile → Toggle "Include Repository Map"

---

## MCP Servers

**Model Context Protocol (MCP)** allows you to extend agent capabilities by connecting to external tools and services. MCP servers expose tools to the agent via a standardized protocol.

### What Are MCP Servers?

MCP servers are external processes (CLI tools, web services, Docker containers) that provide additional tools to the agent. Examples:

- **Database access** (query databases)
- **Web browsing** (search, scrape, interact with websites)
- **API integrations** (Slack, GitHub, Jira, etc.)
- **Custom business logic** (domain-specific operations)

### MCP Server Configuration

MCP servers are configured in **Settings → Agent → MCP Servers**.

#### Configuration Format

Each MCP server is defined by:

**STDIO (Command-line)**:
```json
{
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-example"],
  "env": {
    "API_KEY": "your-api-key"
  }
}
```

**HTTP/SSE (Web service)**:
```json
{
  "url": "https://mcp-server.example.com",
  "headers": {
    "Authorization": "Bearer your-token"
  }
}
```

#### Variable Interpolation

MCP server configurations support variable substitution:

- `${projectDir}`: Project root directory
- `${taskDir}`: Task directory (worktree or project root)

**Example**:
```json
{
  "command": "python",
  "args": ["${projectDir}/scripts/mcp-server.py"],
  "env": {
    "WORK_DIR": "${taskDir}"
  }
}
```

### Enabling MCP Servers Per Profile

Once an MCP server is configured globally, enable it per-profile:

1. Settings → Agent → Select Profile
2. Scroll to "Enabled MCP Servers"
3. Check servers to enable for this profile

### MCP Tool Approvals

Each tool exposed by an MCP server can have individual approval settings (Always, Ask, Never), just like built-in tools.

### MCP Server Lifecycle

- **Connection**: MCP clients connect when the agent profile is activated
- **Tool Discovery**: Tools are fetched via `listTools()` RPC
- **Invocation**: Tools are called via `callTool()` RPC
- **Timeout**: MCP requests have a 10-minute timeout (`MCP_CLIENT_TIMEOUT`)

### Example: Adding a Custom MCP Server

1. Create an MCP server (following MCP SDK documentation)
2. Add server config to Settings → Agent → MCP Servers
3. Enable the server in your agent profile
4. Set approval levels for each tool
5. Agent can now use the new tools

---

## Tool Approval System

Every tool (Power Tools, Aider Tools, MCP Tools, etc.) has an **approval state** that controls when the agent can use it.

### Approval States

| State | Behavior |
|-------|----------|
| **Always** | Auto-approve, no prompt |
| **Ask** | Prompt user for approval each time |
| **Never** | Disable tool completely (not available to agent) |

### Approval Configuration

**Via UI**: Settings → Agent → Profile → Scroll to tool group → Set individual tool approvals

**In Profile JSON**:
```json
{
  "toolApprovals": {
    "power---file_read": "Always",
    "power---file_write": "Ask",
    "power---bash": "Ask",
    "aider---run_prompt": "Ask",
    "tasks---create_task": "Ask"
  }
}
```

### Approval Dialog Options (Runtime)

When a tool requires approval, the UI presents:

- **Yes**: Approve this invocation
- **No**: Deny this invocation
- **Always**: Set approval to "Always" for this tool
- **Always for This Run**: Auto-approve for the current task session

### Security Best Practices

1. **Start conservative**: Use "Ask" for all tools when learning
2. **Review bash commands**: Always inspect shell commands before approval
3. **Use "Never"** for tools you don't need (reduce attack surface)
4. **Project-specific profiles**: Use stricter approvals for sensitive projects
5. **Monitor tool usage**: Review message history for unexpected tool calls

### Bash Tool Pattern Filtering

The `power---bash` tool supports **allowed** and **denied** regex patterns for extra security:

**Settings → Agent → Profile → Tool Settings → bash**:
```json
{
  "allowedPattern": "ls .*;git status;git log;npm test",
  "deniedPattern": "rm -rf.*;sudo .*;chmod .*;chown .*"
}
```

- Commands matching `allowedPattern` auto-approve (skip approval dialog)
- Commands matching `deniedPattern` are blocked (cannot be approved)

---

## API Reference

All agent profile and tool configurations can be managed via REST API.

### Agent Profile Endpoints

**Base URL**: `http://localhost:<port>/api` (port configured in Settings → Advanced → REST API Port)

#### `GET /agent-profiles`

**Description**: Retrieves all agent profiles (global + project-specific).

**Response**:
```json
[
  {
    "id": "default",
    "name": "Power Tools",
    "provider": "anthropic",
    "model": "claude-sonnet-4-5-20250929",
    "usePowerTools": true,
    "useAiderTools": false,
    "toolApprovals": { ... },
    "enabledServers": []
  }
]
```

---

#### `POST /agent-profile/create`

**Description**: Creates a new agent profile.

**Request Body**:
```json
{
  "profile": { ... },
  "projectDir": "/path/to/project" // optional, for project-level profile
}
```

**Response**: Updated list of all profiles.

---

#### `POST /agent-profile/update`

**Description**: Updates an existing agent profile.

**Request Body**:
```json
{
  "profile": { ... }
}
```

**Response**: Updated list of all profiles.

---

#### `POST /agent-profile/delete`

**Description**: Deletes an agent profile.

**Request Body**:
```json
{
  "profileId": "my-profile"
}
```

**Response**: Updated list of all profiles.

---

#### `POST /agent-profiles/order`

**Description**: Updates the display order of agent profiles.

**Request Body**:
```json
{
  "agentProfiles": [ ... ] // array of profiles in desired order
}
```

**Response**:
```json
{
  "success": true
}
```

---

### MCP Server Endpoints

#### `GET /mcp/servers`

**Description**: Lists all configured MCP servers.

**Response**:
```json
{
  "server-name": {
    "command": "npx",
    "args": ["-y", "mcp-server"],
    "env": { ... }
  }
}
```

---

#### `GET /mcp/server/:serverName/tools`

**Description**: Gets tools exposed by a specific MCP server.

**Response**:
```json
[
  {
    "name": "tool_name",
    "description": "Tool description",
    "inputSchema": { ... },
    "serverName": "server-name"
  }
]
```

---

#### `POST /mcp/server/add`

**Description**: Adds or updates an MCP server configuration.

**Request Body**:
```json
{
  "serverName": "my-server",
  "config": {
    "command": "python",
    "args": ["server.py"],
    "env": {}
  }
}
```

---

#### `POST /mcp/server/remove`

**Description**: Removes an MCP server configuration.

**Request Body**:
```json
{
  "serverName": "my-server"
}
```

---

### Enabling Tools via API

Tools are enabled/disabled via agent profile configuration:

**Step 1**: Fetch profiles via `GET /agent-profiles`
**Step 2**: Modify profile's `toolApprovals` object:
```json
{
  "toolApprovals": {
    "power---file_read": "Always",
    "power---bash": "Ask",
    "aider---run_prompt": "Ask",
    "mcp-server-name---tool_name": "Always"
  }
}
```
**Step 3**: Update via `POST /agent-profile/update`

---

## Tool Naming Convention

All tools follow a consistent naming pattern:

```
<group-name>---<tool-name>
```

**Examples**:
- `power---file_read`
- `aider---run_prompt`
- `tasks---create_task`
- `todo---set_items`
- `memory---store_memory`
- `<mcp-server-name>---<tool-name>` (for MCP tools)

This pattern is used in:
- Tool IDs
- Approval settings (`toolApprovals` object)
- UI display
- API responses

---

## Summary

AiderDesk's tool ecosystem provides a comprehensive, extensible platform for AI-powered development:

- **Power Tools**: Direct file and system operations for fast, targeted work
- **Aider Tools**: Delegate complex code generation to Aider's engine
- **Task Tools**: Multi-task management for organizing complex projects
- **Todo Tools**: In-task planning and progress tracking
- **Memory Tools**: Persistent project knowledge with semantic retrieval
- **Repository Map**: High-level codebase overview for architectural context
- **MCP Servers**: Extend capabilities with custom tools and integrations

All tools are **profile-scoped** (enable per-profile), **approval-controlled** (Always/Ask/Never), and **API-accessible** (full REST API support).

For detailed UI workflows, see the [Agent Mode documentation](../docs-site/docs/agent-mode/agent-mode.md).
For MCP server development, see the [MCP SDK documentation](https://modelcontextprotocol.io).

---

**End of Power Tools & MCP Servers Reference**
