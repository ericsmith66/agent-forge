# Ruby on Rails Global Agent Config (AiderDesk) — Enterprise

> **Audience**: Rails teams using AiderDesk agent profiles + skills at enterprise scale
> **Last updated**: 2026-02-12

---

## Goal

Provide a **full best-practices, global** AiderDesk configuration for Ruby on Rails work using **agent profiles** and a **comprehensive skills catalog**. This setup is designed for:

- **Greenfield** work (new features from scratch)
- **Refactors** (behavior-preserving improvements)
- **Debugging** (reproduction-first fixes)
- **Enterprise constraints** (security, reliability, observability, performance)

---

## File Locations (Global)

```
~/.aider-desk/
├── agents/
│   ├── rails-greenfield/
│   │   ├── config.json
│   │   └── rules/
│   │       ├── coding-standards.md
│   │       ├── architecture.md
│   │       └── custom-instructions.md
│   ├── rails-refactor/
│   │   ├── config.json
│   │   └── rules/
│   │       ├── coding-standards.md
│   │       ├── architecture.md
│   │       └── custom-instructions.md
│   ├── rails-debug/
│   │   ├── config.json
│   │   └── rules/
│   │       ├── coding-standards.md
│   │       ├── architecture.md
│   │       └── custom-instructions.md
│   └── rails-ui/
│       ├── config.json
│       └── rules/
│           ├── coding-standards.md
│           ├── architecture.md
│           └── custom-instructions.md
└── skills/
    ├── rails-service-patterns/
    │   └── SKILL.md
    ├── rails-rspec-webmock/
    │   └── SKILL.md
    ├── rails-error-handling-logging/
    │   └── SKILL.md
    ├── rails-activerecord-performance/
    │   └── SKILL.md
    ├── rails-background-jobs/
    │   └── SKILL.md
    ├── rails-api-design/
    │   └── SKILL.md
    ├── rails-security/
    │   └── SKILL.md
    ├── rails-caching/
    │   └── SKILL.md
    ├── rails-testing-strategy/
    │   └── SKILL.md
    ├── rails-data-integrity/
    │   └── SKILL.md
    ├── rails-observability-metrics/
    │   └── SKILL.md
    ├── rails-tailwind-ui/
    │   └── SKILL.md
    ├── rails-daisyui-components/
    │   └── SKILL.md
    └── rails-turbo-hotwire/
        └── SKILL.md
```

> **Project override**: place the same structure under `<project>/.aider-desk/` to override global profiles/skills with matching IDs.

---

## Profile Best Practices

### 1) Greenfield Profile (`rails-greenfield`)

**Intent**: Create new files and features from scratch with minimal refactors.

**`config.json`**
```json
{
  "maxIterations": 10,
  "temperature": 0.8,
  "includeContextFiles": true,
  "includeRepoMap": true,
  "useAiderTools": true,
  "usePowerTools": true,
  "useTodoTools": false,
  "useSkillsTools": true,
  "toolApprovals": {
    "aider": "Always",
    "power": "Ask",
    "todo": "Never",
    "skills": "Always"
  },
  "customInstructions": "Create new files from scratch. Prefer whole-file edits. Avoid refactors unless explicitly requested. Align with enterprise security and observability defaults."
}
```

**`rules/custom-instructions.md`**
```
Create new files from scratch.
Prefer whole-file edits.
Avoid refactors unless explicitly requested.
Apply enterprise defaults for security, observability, and testing.
```

---

### 2) Refactor Profile (`rails-refactor`)

**Intent**: Preserve behavior and tighten code with minimal diffs and test updates.

**`config.json`**
```json
{
  "maxIterations": 18,
  "temperature": 0.7,
  "includeContextFiles": true,
  "includeRepoMap": true,
  "useAiderTools": true,
  "usePowerTools": true,
  "useTodoTools": true,
  "useSkillsTools": true,
  "toolApprovals": {
    "aider": "Always",
    "power": "Ask",
    "todo": "Always",
    "skills": "Always"
  },
  "customInstructions": "Preserve behavior. Prefer minimal diffs. Update or add tests for changed behavior. Maintain production-safe rollouts and observability."
}
```

**`rules/custom-instructions.md`**
```
Preserve behavior.
Prefer minimal diffs.
Update or add tests for changed behavior.
Maintain production-safe rollouts and observability.
```

---

### 3) Debug Profile (`rails-debug`)

**Intent**: Reproduce first, then fix with evidence.

**`config.json`**
```json
{
  "maxIterations": 12,
  "temperature": 0.4,
  "includeContextFiles": true,
  "includeRepoMap": true,
  "useAiderTools": true,
  "usePowerTools": true,
  "useTodoTools": false,
  "useSkillsTools": true,
  "toolApprovals": {
    "aider": "Always",
    "power": "Ask",
    "todo": "Never",
    "skills": "Always"
  },
  "customInstructions": "Reproduce first, then fix. Provide evidence from logs/tests. Add guardrails to prevent regressions."
}
```

**`rules/custom-instructions.md`**
```
Reproduce first, then fix.
Provide evidence from logs/tests.
Add guardrails to prevent regressions.
```

---

### 4) UI Profile (`rails-ui`)

**Intent**: Deliver enterprise-grade UI with Tailwind, DaisyUI, and Turbo.

**`config.json`**
```json
{
  "maxIterations": 12,
  "temperature": 0.6,
  "includeContextFiles": true,
  "includeRepoMap": true,
  "useAiderTools": true,
  "usePowerTools": true,
  "useTodoTools": false,
  "useSkillsTools": true,
  "toolApprovals": {
    "aider": "Always",
    "power": "Ask",
    "todo": "Never",
    "skills": "Always"
  },
  "customInstructions": "Focus on UI/UX in Rails views and components. Use Tailwind + DaisyUI utilities and Turbo for interactivity. Enforce accessibility, responsive design, and i18n-friendly markup. Avoid introducing new frontend frameworks unless requested."
}
```

**`rules/custom-instructions.md`**
```
Focus on UI/UX in Rails views and components.
Use Tailwind + DaisyUI utilities and Turbo for interactivity.
Enforce accessibility, responsive design, and i18n-friendly markup.
Avoid introducing new frontend frameworks unless requested.
```

---

## Skill Catalog (Enterprise)

Each skill follows the same template with **When to use**, **Required conventions**, **Examples**, and **Do/Don’t** guidance.

- `rails-service-patterns`
- `rails-rspec-webmock`
- `rails-error-handling-logging`
- `rails-activerecord-performance`
- `rails-background-jobs`
- `rails-api-design`
- `rails-security`
- `rails-caching`
- `rails-testing-strategy`
- `rails-data-integrity`
- `rails-observability-metrics`
- `rails-tailwind-ui`
- `rails-daisyui-components`
- `rails-turbo-hotwire`

---

## Notes for Enterprise Teams

- Keep rules **project-specific**: encode naming conventions, architectural boundaries, and security requirements in the profile rules.
- Use skills to enforce **cross-cutting concerns** like observability, performance, and data integrity.
- Prefer **explicit rollouts**: add migrations safely, use feature flags when needed, and include rollback instructions in PRs.
