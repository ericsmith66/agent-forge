# Ruby on Rails Global Agent Config (AiderDesk)

> **Audience**: Rails teams using AiderDesk agent profiles + skills
> **Last updated**: 2026-02-12

---

## Goal

Provide a **best-practices, global** AiderDesk configuration for Ruby on Rails work using **agent profiles** and **skills**. This setup is designed for:

- **Greenfield** work (new features from scratch)
- **Refactors** (behavior-preserving improvements)
- **Debugging** (reproduction-first fixes)

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
  "maxIterations": 8,
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
  "customInstructions": "Create new files from scratch. Prefer whole-file edits. Avoid refactors unless explicitly requested."
}
```

**`rules/custom-instructions.md`**
```
Create new files from scratch.
Prefer whole-file edits.
Avoid refactors unless explicitly requested.
```

---

### 2) Refactor Profile (`rails-refactor`)

**Intent**: Preserve behavior and tighten code with minimal diffs and test updates.

**`config.json`**
```json
{
  "maxIterations": 16,
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
  "customInstructions": "Preserve behavior. Prefer minimal diffs. Update or add tests for changed behavior."
}
```

**`rules/custom-instructions.md`**
```
Preserve behavior.
Prefer minimal diffs.
Update or add tests for changed behavior.
```

---

### 3) Debug Profile (`rails-debug`)

**Intent**: Reproduce first, collect evidence, then fix.

**`config.json`**
```json
{
  "maxIterations": 10,
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
  "customInstructions": "Reproduce first, then fix. Provide evidence from logs or tests."
}
```

**`rules/custom-instructions.md`**
```
Reproduce first, then fix.
Provide evidence from logs or tests.
```

---

### 4) UI Profile (`rails-ui`)

**Intent**: Build and refine Rails UI using Tailwind, DaisyUI, and Turbo.

**`config.json`**
```json
{
  "maxIterations": 10,
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
  "customInstructions": "Focus on UI/UX changes in Rails views and components. Use Tailwind + DaisyUI utilities and Turbo for interactivity. Prefer minimal JavaScript and avoid new frontend frameworks unless requested."
}
```

**`rules/custom-instructions.md`**
```
Focus on UI/UX changes in Rails views and components.
Use Tailwind + DaisyUI utilities and Turbo for interactivity.
Prefer minimal JavaScript and avoid new frontend frameworks unless requested.
```

---

## Shared Rails Rules (Recommended)

Place shared conventions in each profile’s `rules/` directory:

### `rules/coding-standards.md`
- Prefer `rubocop`-friendly formatting.
- Use `frozen_string_literal: true` only when already present in the file.
- Keep methods short; extract service objects for complex flows.
- Use `ApplicationService` or `BaseService` pattern if the project defines one.

### `rules/architecture.md`
- Keep business logic out of controllers and models where possible.
- Favor POROs under `app/services` or `app/commands` for orchestration.
- Don’t add new gems without explicit approval.

---

## Skills (Rails Playbooks)

Skills are loaded **on demand** and only work when `useSkillsTools: true`.

### Skill Structure
```
~/.aider-desk/skills/<skill-id>/
└── SKILL.md
```

### Skill Template (example)
```markdown
---
name: Rails Service Patterns
description: Service objects, orchestration, and transaction boundaries for Rails.
---

## When to use
- Adding non-trivial business logic
- Coordinating multiple models or side effects

## Required conventions
- Service classes under `app/services`
- Single public `call` method
- Inputs validated at initialization

## Examples
```ruby
class Payments::CaptureCharge
  def initialize(order)
    @order = order
  end

  def call
    ActiveRecord::Base.transaction do
      # ...
    end
  end
end
```

## Do / Don’t
**Do**:
- Keep services small and focused
- Return structured results (success/failure)

**Don’t**:
- Hide side effects in model callbacks
- Mix HTTP concerns into services
```

### Recommended Rails Skills
- `rails-service-patterns`
- `rails-rspec-webmock`
- `rails-error-handling-logging`
- `rails-tailwind-ui`
- `rails-daisyui-components`
- `rails-turbo-hotwire`

---

## Operational Notes

- **Profiles are hierarchical**: project-level profiles override globals with the same ID.
- **Skills are opt-in**: they won’t load unless the active profile enables `useSkillsTools`.
- **Tool approvals**: set to `Ask` for safety on Power Tools in shared environments.

---

## Quick Checklist

- [ ] Create the three profiles under `~/.aider-desk/agents/`
- [ ] Add `config.json` + `rules/` per profile
- [ ] Create Rails skills under `~/.aider-desk/skills/`
- [ ] Ensure profiles have `useSkillsTools: true`
- [ ] Confirm your active task uses the intended profile

---

**End of Rails Global Config Guide**
