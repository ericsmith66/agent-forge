Here is a clean, self-contained bootstrap document you can copy-paste into your new project called **AgentForge**.

Save it as something like `README.md`, `BOOTSTRAP.md`, or `docs/00-bootstrap-context.md` in your new repo (`https://github.com/ericsmith66/agentforge` or local equivalent).

The goal is to give any AI (Grok, Claude, Junie, Ollama model, etc.) or human developer immediate, high-fidelity context without touching or referencing the nextgen-plaid repo directly.

```markdown
# AgentForge – Bootstrap Context Document

## Project Overview
AgentForge is a standalone, local-first **agent orchestration & meta-development hub**.  

It lives completely separate from application codebases (e.g. nextgen-plaid, future Rails/Python projects).  

Purpose:  
- Serve as an "IDE-like" external workspace for planning, task decomposition, PRD/epic generation, code writing/review, and agent coordination.  
- Enable switching between projects without muddying their repositories.  
- Bootstrap itself using AI agents (meta).  
- Eventually support multi-agent workflows similar to MetaGPT/CrewAI style, but tailored for Ruby/Rails-heavy development with strong Rails conventions.

Core philosophy:  
- Artifacts (personas, prompts, templates, RAG context, logs) are **never** committed inside target application repos.  
- Agent outputs (PRDs, code diffs, generated files) are reviewed/copied/committed manually or via hooks into target projects.  
- Local-only execution preferred (Ollama + smart proxy for model flexibility).  
- Privacy & control first: no cloud unless explicit.

## Current Capabilities to Replicate / Achieve Parity With
(From previous working workflow – do not assume files exist here yet; bootstrap them)

- **Personas**: YAML-defined roles (e.g. SAP – Strategic Architecture Persona for high-level planning/PRDs)  
- **Prompts & Templates**: Structured prompt files for planning (PRD generation), task breakdown, code writing guardrails  
- **RAG / Context Injection**: Simple file-based (no vector DB)  
  - inventory.json → lists artifacts with paths, descriptions, priority  
  - Static MD files (e.g. 0_AI_THINKING_CONTEXT.md – reasoning guidelines)  
  - Per-project folders (snapshots, PRDs, mocks)  
  - Concatenation into prompts for LLM calls  
- **Smart Proxy**: Thin layer to route LLM requests (Ollama local default, fallback to Claude/Grok/etc.)  
- **Logging**: Detailed traces of agent runs (prompts, outputs, decisions, timestamps)  
- **Workflow Style**: Human-in-loop + AI assistance (Grok for planning, Junie in RubyMine for implementation)

## Tech & Environment Targets
- **Language**: Ruby (primary), with Python allowed for simulators/calculators if needed later  
- **LLM Access**: Ollama (local) – preferred models:  
  - llama3.1:70b or 405b (reasoning)  
  - deepseek-coder (code generation)  
  - Via smart proxy → can also use Claude Sonnet, Grok, Gemini, etc.  
- **Runner**: Initially scripts + CLI (later optional Sinatra/ lightweight Rails for web UI if desired)  
- **Dependencies**: Minimal – httparty (Ollama calls), yaml, json, dotenv  
- **Git**: Feature branches, green commits only, review diffs  
- **IDE**: RubyMine + Junie Pro (Claude Sonnet 4.5 default) for implementation

## Directory Structure Goal (Bootstrap This)
```
agentforge/
├── agents/                 # Role implementations (SAP, Coordinator, CWA stubs)
│   ├── sap.rb
│   ├── coordinator.rb
│   └── cwa/                # Initially Aider subprocess wrapper
├── knowledge/              # Shared & reusable artifacts
│   ├── personas.yml
│   ├── prompts/
│   ├── templates/
│   └── contexts/
│       └── 0_AI_THINKING_CONTEXT.md
├── rag/                    # RAG-specific
│   ├── inventory.json
│   ├── loaders/
│   │   └── rag_loader.rb
│   ├── projects/           # per-project folders
│   └── templates/          # prompt injection templates
├── logs/                   # Agent run traces (timestamped or run-id folders)
├── scripts/                # Entry points
│   ├── run_sap.rb
│   ├── run_coordinator.rb
│   └── test_rag.rb
├── .env                    # OLLAMA_HOST, DEFAULT_MODEL, RAG_PATH, etc.
├── Gemfile
└── README.md               # This file or link to it
```

## Initial Bootstrap Tasks (Priority Order)
1. Create repo structure above (dirs + .gitignore + Gemfile + .env.example)  
2. Implement basic RAG loader (inventory.json → concatenated context string)  
3. Create SAP stub: load persona/prompt + RAG → generate PRD text via Ollama  
4. Add smart proxy wrapper for LLM calls (Ollama default)  
5. Strap on Aider as initial CWA (subprocess call with repo path, task prompt)  
6. Add logging for all runs (prompt, response, metadata)  
7. Test end-to-end: generate a small PRD for a dummy feature

## Key Constraints & Guardrails
- Local-only by default (no external API calls unless via explicit proxy config)  
- Rails MVC + privacy patterns (attr_encrypted, RLS) when generating code for target projects  
- No premature UI – focus on scriptable, CLI-first  
- Outputs should be copy-paste friendly (Markdown PRDs, code blocks, diffs)  
- Always prefer structured output from LLMs when possible

## First Prompt Suggestion for Any AI (Grok / Claude / Ollama)
```
You are helping bootstrap AgentForge – a standalone agent orchestration hub.
Follow the structure and goals in the BOOTSTRAP.md document above.
Task: Create the initial directory structure and populate the first files:
- .env.example
- rag/inventory.json (with 2-3 placeholder entries)
- rag/loaders/rag_loader.rb (simple class to build context string)
- agents/sap.rb (basic class that loads a persona and calls Ollama)
  Commit only green, working code.
  Ask questions if anything is unclear.
```

Copy this entire document into your new AgentForge repo and start from there.  

Let me know if you want to expand any section (e.g. sample inventory.json content, rag_loader.rb skeleton, or first prompt variations).  
Ready to move to the next step?  
What do you want to tackle first?