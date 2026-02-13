# Epic 5 AiderDesk Shared Config (Rails)

This is a **shared config library** meant to be symlinked into project-local `.aider-desk/` folders per the Epic 5 plan. It follows the **hierarchical Agent → Subagent** model and includes **rules**, **skills**, **commands**, and **hooks** aligned to the Epic 5 constraints.

## Structure
```
knowledge_base/epic-5/ror-agent-forge-config/
├── agents/
│   └── rails/
│       ├── agent.md
│       ├── config.json
│       ├── rules/
│       │   ├── architecture.md
│       │   ├── coding-standards.md
│       │   └── custom-instructions.md
│       └── subagents/
│           ├── debug/
│           │   ├── config.json
│           │   └── rules/custom-instructions.md
│           ├── greenfield/
│           │   ├── config.json
│           │   └── rules/custom-instructions.md
│           ├── refactor/
│           │   ├── config.json
│           │   └── rules/custom-instructions.md
│           └── ui/
│               ├── config.json
│               └── rules/custom-instructions.md
├── commands/
│   └── epic5/
│       └── prd-5-01/..
├── hooks/
│   └── epic5-guardrails.js
├── rules/
│   ├── epic-5-compliance-checklist.md
│   └── epic-5-strict-directive.md
└── skills/
    ├── rails-control-events-audit/
    ├── rails-open3-safe-exec/
    ├── rails-rspec-webmock/
    ├── rails-service-patterns/
    ├── rails-stimulus-controls/
    └── rails-webhook-dedupe/
```

## How to Apply (Symlink Strategy)
Create a physical `.aider-desk/` directory in each repo and symlink subfolders only:

```
.aider-desk/
├── agents   -> knowledge_base/epic-5/ror-agent-forge-config/agents
├── skills   -> knowledge_base/epic-5/ror-agent-forge-config/skills
├── commands -> knowledge_base/epic-5/ror-agent-forge-config/commands
├── hooks    -> knowledge_base/epic-5/ror-agent-forge-config/hooks
└── rules    -> knowledge_base/epic-5/ror-agent-forge-config/rules
```

## Notes
- This config set assumes **Rails best practices** and Epic 5 constraints.
- The **STRICT EXECUTION DIRECTIVE** is a **global rule** in `rules/epic-5-strict-directive.md` and should be loaded before any PRD-specific rule.
- Command templates under `commands/epic5/` explicitly load the PRD file, the Epic 5 plan, and the strict directive rule.
