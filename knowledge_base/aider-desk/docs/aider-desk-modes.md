# AiderDesk Modes Reference

> **Audience**: Senior developers working with AiderDesk
> **Last updated**: 2026-02-09

---

## Overview

AiderDesk exposes **six interaction modes** that control how your prompt is processed, what tools are available, and whether the AI can modify files. They appear in the mode selector (bottom-left of the prompt field) in this order:

| Mode | Icon | Modifies Files | Autonomous | Underlying Engine | Typical Use |
|------|------|:-:|:-:|---|---|
| **Agent** | 🤖 | ✅ | ✅ | Vercel AI SDK + tool ecosystem | Multi-step autonomous work |
| **Code** | ⌨️ | ✅ | ❌ | Aider | Direct code generation & edits |
| **BMAD** | 🔷 | ✅ | ✅ | BMAD Method workflow engine + Agent | Structured agile methodology workflows |
| **Ask** | ❓ | ❌ | ❌ | Aider | Codebase Q&A, explanations |
| **Architect** | 📐 | ✅ (via handoff) | ❌ | Aider (two-model) | High-level design → implementation |
| **Context** | 🔍 | ❌ | ❌ | Aider | Manage context files only |

The four **Aider-native modes** (`code`, `ask`, `architect`, `context`) map directly to Aider's built-in capabilities. The two **AiderDesk-extended modes** (`agent`, `bmad`) layer orchestration on top.

```typescript
type Mode = 'code' | 'ask' | 'architect' | 'context' | 'agent' | 'bmad';
```

---

## Mode Details

### Agent Mode

**What it does**: Activates AiderDesk's autonomous AI agent (powered by the Vercel AI SDK). The agent plans, reasons, uses tools, and executes multi-step workflows independently.

**When to use it**:
- Complex tasks: "Implement OAuth with Google, including tests and error handling"
- Exploratory work: "Find all usages of the deprecated API and migrate them"
- Multi-file refactors that require codebase exploration first
- Tasks where you'd normally do multiple Code-mode prompts in sequence

**How it works**:
1. Your prompt is sent to the agent's LLM (configured via Agent Settings — can differ from the Aider main model)
2. The agent creates a **plan** and begins executing steps autonomously
3. At each step, the agent can invoke **tools**:
    - **Power Tools**: File read/write, grep, semantic search, shell commands, web fetch
    - **Aider Tools**: Code generation and modification (delegates to Aider under the hood)
    - **Memory Tools**: Store/retrieve project knowledge from local vector DB (LanceDB)
    - **MCP Tools**: Any connected MCP server capabilities
    - **Task/Todo Tools**: Manage tasks and checklists
    - **Skills**: Load domain-specific expertise on demand
4. Tool approvals can be configured per-profile: `Always`, `Ask`, or `Never`
5. The agent continues until the task is complete or you interrupt

**Key characteristics**:
- **Multi-turn, multi-tool**: The agent loops through plan → act → observe cycles
- **Subagents**: Can delegate to specialized sub-agents (e.g., a code-review subagent with a cheaper model)
- **Persistent memory**: Retrieves relevant memories at task start; stores outcomes after completion
- **Profiles**: Switch between pre-built profiles (Power Tools, Aider, Aider + Power Search) or create custom ones with specific system prompts, tool permissions, and rules
- **Transparent**: All reasoning, tool calls, and results are visible in the chat
- **Interruptible**: Interrupt at any time via the UI or `POST /api/project/interrupt`
- **Default mode**: New tasks default to Agent mode

**Cost profile**: Highest. Multiple LLM calls + tool invocations. Use model tiering (premium for planning, budget for routine steps) and subagent delegation to manage costs.

---

### Code Mode

**What it does**: Sends your prompt directly to Aider's code-editing engine. The LLM sees your context files and generates **file edits** (diffs) that are applied to your working tree.

**When to use it**:
- You know exactly what you want changed and can describe it in a single prompt
- Targeted refactors: "Extract this method", "Add error handling to X"
- Generating boilerplate or new files from a clear specification

**How it works**:
1. Your prompt + context files are sent to the configured **main model**
2. Aider produces edits in the configured **edit format** (`diff`, `udiff`, `whole`, `diff-fenced`, `udiff-simple`, `patch`)
3. Edits are applied; if auto-commit is enabled, a commit is created

**Key characteristics**:
- **Single-turn**: One prompt → one set of edits. No planning, no tool calls.
- **Edit format matters**: The model's edit format (configurable per-model) affects accuracy. `diff` and `udiff` are token-efficient; `whole` is safest for smaller files.
- **Context is everything**: Only files in your context are visible. If the model needs to see a file, add it first.
- **Auto-commit**: When enabled, successful edits generate a git commit automatically.

**Cost profile**: Single LLM call. Cheapest mode for targeted work.

---

### BMAD Mode

**What it does**: Activates the **BMAD (Breakthrough Method of Agile AI-Driven Development)** workflow engine. BMAD provides structured, methodology-driven workflows that span the full software development lifecycle — from research and product briefs through architecture, story creation, and implementation.

**When to use it**:
- Greenfield projects that need structured planning before coding
- Requirements gathering and story creation following agile methodology
- Architecture design with formal documentation output
- Sprint planning and story-driven development with code review
- When you want a guided, step-by-step workflow rather than freeform prompting
- Quick specs and rapid development for smaller, well-defined features

**How it works**:
1. BMAD must be **installed** per-project (installs the `bmad-method` library into `_bmad/bmm/`)
2. You select a workflow from the BMAD panel; workflows are organized by **phase**
3. Each workflow follows a structured methodology with defined inputs, steps, and outputs
4. Workflows execute via **Agent Mode** under the hood — BMAD prepares context messages and context files, then delegates to the agent
5. Outputs are written to `_bmad-output/` as structured artifacts (markdown docs, YAML configs)
6. Workflow state is tracked: BMAD detects completed, in-progress, and available workflows
7. Workflow state can be reset by clearing `_bmad-output/`

**Workflow Phases & Registry** (in execution order):

| Phase | Workflow | Description | Output Artifact |
|-------|----------|-------------|-----------------|
| **Analysis** | Research | Web research across multiple domains | `research*.md` |
| **Analysis** | Create Product Brief | Define product vision and target users | `product-brief*.md` |
| **Planning** | Create PRD | Comprehensive requirements document | `prd.md` |
| **Planning** | Create UX Design | UX design documentation | `ux-design*.md` |
| **Solutioning** | Create Architecture | Technical architecture and system structure | `architecture.md` |
| **Solutioning** | Create Epics & Stories | Break down requirements into epics/stories | `epics.md` |
| **Implementation** | Sprint Planning | Generate sprint status tracking | `sprint-status.yaml` |
| **Implementation** | Create Story | Guided story creation for implementation | (per story) |
| **Implementation** | Dev Story | Implement tasks/subtasks, write tests, validate | (per story) |
| **Implementation** | Code Review | Adversarial senior developer code review | `code-review*.md` |
| **Quick Flow** | Quick Spec | Focused specs for well-defined features | `tech-spec-*.md` |
| **Quick Flow** | Quick Dev | Rapid spec-to-implementation | N/A |

**Dependency chain**: Workflows declare required artifacts. For example:
- `Create PRD` requires `product-brief*.md`
- `Create Architecture` requires `prd.md`
- `Create Epics & Stories` requires both `prd.md` and `architecture.md`
- `Sprint Planning` requires `epics.md`

**Key characteristics**:
- **Structured methodology**: Unlike Agent mode's freeform autonomy, BMAD follows prescribed workflows with defined phases
- **Project-scoped**: BMAD is installed per-project; artifacts live in `_bmad-output/`
- **Document-oriented**: Outputs are structured markdown/YAML artifacts
- **Artifact-aware**: Tracks which workflows are complete, in-progress, or available based on existing artifacts
- **Agent-powered execution**: Workflows delegate to Agent mode for actual LLM work — the agent profile on the current task is used
- **Resumable**: In-progress workflows can be detected and resumed from where they left off
- **Resettable**: `POST /api/bmad/reset-workflow` clears all output and starts fresh
- **Quick Flow shortcut**: For smaller features, skip the full lifecycle and use Quick Spec → Quick Dev

**REST API**:
- `GET /api/bmad/status` — Installation status, available/completed/in-progress workflows
- `GET /api/bmad/workflows` — List all workflow metadata
- `POST /api/bmad/install` — Install BMAD library into project
- `POST /api/bmad/execute-workflow` — Execute a specific workflow (`{ projectDir, taskId, workflowId }`)
- `POST /api/bmad/reset-workflow` — Clear `_bmad-output/` and reset state

**Cost profile**: Variable, depends on workflow complexity. Each workflow step involves agent-mode LLM calls. Full lifecycle (Research → Code Review) is the most expensive; Quick Spec → Quick Dev is lightweight.

**Comparison with Agent mode**:

| | Agent | BMAD |
|---|---|---|
| Structure | Freeform, prompt-driven | Prescribed phases & workflows |
| Planning | Ad-hoc (agent decides) | Methodology-defined steps |
| Output | Code changes + chat | Structured artifacts + code |
| Scope | Any task | Full SDLC or Quick Flow |
| Resumability | Via task history | Built-in artifact tracking |
| Execution | Direct | Delegates to Agent mode |

---

### Ask Mode

**What it does**: Sends your prompt to the LLM in a **read-only** context. The model can see your context files but **cannot propose or apply edits**.

**When to use it**:
- Understanding unfamiliar code: "Explain the authentication flow in this project"
- Architecture questions: "What are the trade-offs of this caching strategy?"
- Debugging: "Why might this function return null when called from X?"
- Pre-flight checks before making changes

**How it works**:
1. Your prompt + context files are sent to the main model
2. The model responds with text only — no edit blocks are generated
3. No files are modified; no commits are created

**Key characteristics**:
- **Safe by design**: Zero chance of unintended file modifications
- **Full codebase awareness**: Context files are loaded the same as Code mode
- **Great for planning**: Use Ask mode to explore, then switch to Code or Agent to execute

**Cost profile**: Single LLM call. Equivalent to Code mode minus the edit overhead.

---

### Architect Mode

**What it does**: Implements a **two-phase, two-model workflow**. A high-capability "architect" model designs the solution, then a "coder" model (your main model) translates that design into file edits.

**When to use it**:
- Complex features that benefit from top-down design before implementation
- When you want a premium model (e.g., Claude Opus, o1) to plan but a cost-effective model to write code
- Refactoring decisions that require careful architectural thinking
- Teaching moments: See how an expert model approaches design before code

**How it works**:
1. Your prompt + context files are sent to the **architect model** (configured separately in settings)
2. The architect model produces a high-level design or plan (text only, no code)
3. That design is passed to the **main model** (your regular Aider model)
4. The main model implements the design as file edits

**Key characteristics**:
- **Two LLM calls**: One for design, one for implementation
- **Model flexibility**: Use different models for different strengths (e.g., o1 for reasoning, Sonnet for speed)
- **Design artifacts**: The architect's response becomes part of the chat history
- **Still modifies files**: Unlike Ask mode, Architect mode produces actual edits via the coder phase

**Cost profile**: Medium-high. Two LLM calls, but you control which models are used for each phase.

---

### Context Mode

**What it does**: Allows you to **manage context files** without sending a prompt to the LLM. You can add, remove, or refresh files in the context.

**When to use it**:
- Adding files to context before a Code or Ask prompt
- Cleaning up context to reduce token usage
- Refreshing file content after external changes (e.g., a git pull)

**How it works**:
1. You interact with the file tree or use `/add`, `/drop`, `/ls` commands
2. No LLM calls are made
3. Context changes are persisted to the task

**Key characteristics**:
- **Zero cost**: No LLM invocations
- **Preparatory**: Use it to set up context, then switch modes to prompt
- **Manual control**: Unlike Agent mode (which can add files dynamically), Context mode requires explicit user action

**Cost profile**: Free. No LLM usage.

---

## Mode Selection Flow

```
User prompt arrives
    ↓
Is BMAD workflow active?
    Yes → BMAD mode (delegate to Agent)
    No  ↓
Check mode selector
    ↓
┌─────────────────────────────────────────┐
│ Agent:     Plan + Tools + Multi-turn    │
│ Code:      Direct edit (single-turn)    │
│ BMAD:      Structured workflow          │
│ Ask:       Read-only Q&A                │
│ Architect: Design → Code (two models)   │
│ Context:   Manage files (no LLM)        │
└─────────────────────────────────────────┘
```

---

## Quick Reference: When to Use Each Mode

| You want to... | Use this mode |
|----------------|---------------|
| Explore/understand code | **Ask** |
| Make a targeted code change | **Code** |
| Build a complex feature end-to-end | **Agent** |
| Follow agile methodology from requirements to code | **BMAD** |
| Get expert design before implementation | **Architect** |
| Add files to context for next prompt | **Context** |
| Automate multi-step workflows | **Agent** |
| Minimize token usage for simple edits | **Code** |
| Generate PRDs, architecture docs, stories | **BMAD** |
| Ask questions without risk of edits | **Ask** |

---

## Mode-Specific Settings

### Agent Mode Settings
- **Agent Profile**: Power Tools, Aider, Aider + Power Search, or custom
- **Agent Model**: Can differ from main Aider model
- **Tool Approval**: Always, Ask, or Never (per tool category)
- **System Prompt**: Customizable per profile
- **Memory**: Enable/disable persistent memory
- **Skills**: Load domain-specific knowledge on demand

### Code/Ask/Architect Settings
- **Main Model**: The model used for code generation (Code, Ask) or implementation (Architect)
- **Architect Model**: The model used for design phase (Architect only)
- **Edit Format**: How diffs are generated (`diff`, `udiff`, `whole`, etc.)
- **Auto-commit**: Automatically create git commits after edits (Code mode)

### BMAD Settings
- **Installation**: Per-project; installs `bmad-method` library
- **Workflow Selection**: Choose from workflow registry
- **Output Directory**: `_bmad-output/` (configurable)
- **Agent Profile**: Uses the current task's agent profile for execution

### Context Mode
- No model settings (no LLM calls)

---

## Mode Transitions

You can switch modes mid-task:
- **Agent → Code**: Hand off to direct editing after exploration
- **Ask → Code/Agent**: Understand first, then act
- **BMAD → Agent**: BMAD workflows delegate to Agent automatically
- **Context → Any**: Prepare context, then prompt in any mode

Mode changes are reflected in the UI immediately and affect the next message only.

---

## Advanced: Mode Implementation

| Mode | Entry Point | Primary Code Path |
|------|-------------|-------------------|
| Agent | `POST /api/agent/message` | `lib/agent/core/engine.ts` |
| Code | `POST /api/project/message` | `lib/aider/client.ts` → Aider CLI |
| BMAD | `POST /api/bmad/execute-workflow` | `lib/bmad/engine.ts` → Agent |
| Ask | `POST /api/project/message` | `lib/aider/client.ts` → Aider CLI (read-only) |
| Architect | `POST /api/project/message` | `lib/aider/client.ts` → Aider CLI (two-phase) |
| Context | `POST /api/project/context` | `lib/aider/context.ts` |

All modes share the **task** abstraction (`lib/task/manager.ts`). Tasks track:
- Mode used
- Context files
- Message history
- Agent profile (if Agent/BMAD mode)
- Git state

---

## FAQ

**Q: Can I use multiple modes in the same task?**
A: Yes. Mode changes are per-message. You can Ask, then Code, then Agent in the same task thread.

**Q: What's the difference between Agent mode and BMAD?**
A: Agent is freeform autonomous work; BMAD is structured methodology with prescribed workflows. BMAD uses Agent under the hood.

**Q: Can I disable a mode?**
A: Modes are always available, but you can configure agent profiles to disable certain tools, effectively limiting Agent mode capabilities.

**Q: Which mode is fastest?**
A: Context (no LLM) → Code/Ask (single call) → Architect (two calls) → Agent (multi-turn) → BMAD (multi-step Agent).

**Q: Which mode is cheapest?**
A: Same order as speed: Context is free, Code/Ask are cheapest LLM modes.

**Q: Can I create custom modes?**
A: Not directly, but you can create **custom Agent profiles** with specific tools, prompts, and rules, which effectively acts as a specialized mode.

**Q: Does BMAD require the full workflow every time?**
A: No. You can use **Quick Flow** (Quick Spec → Quick Dev) for smaller features, or jump into any workflow if you have the required artifacts.

---

## Related Documentation

- [Agent Architecture](./agent-architecture.md)
- [BMAD Method Guide](./bmad-guide.md)
- [Aider Integration](./aider-integration.md)
- [Tool System](./tools.md)
- [Memory & Skills](./memory-skills.md)

---

**End of Modes Reference**
