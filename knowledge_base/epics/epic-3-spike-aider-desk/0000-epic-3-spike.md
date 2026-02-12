# Spike Epic: AiderDesk Capability Baseline Evaluation

**Date**: 2026-02-10
**Status**: ✅ **READY FOR IMPLEMENTATION**
**Branch**: `spike/aiderdesk-capability-baseline`
**Objective**:
Time-boxed spike to baseline AiderDesk's capabilities by having it implement a realistic Rails service task (Prefab HTTP Client, modeled after PRD 1.2). Evaluate code quality, test coverage, Rails idioms, error handling, and interaction behavior across modes/models. This informs Epic 3 RAG design and overall agentic coding strategy.

**Spike Duration**: 1–2 days (focused evaluation runs + reporting)
**Dogfood Project**: eureka-homekit-rebuild (use clean worktrees for isolation)

---

## 📋 Document Structure Confirmation
All Spike Epic documents have been created:

### Core Documents
- ✅ `spike-epic-aiderdesk-baseline.md` - Full spike overview with evaluation task and instructions
- ✅ `spike-prd-s1-project-setup.md` - Project and environment setup
- ✅ `spike-prd-s2-evaluation-execution.md` - Run evaluations in modes/models
- ✅ `spike-prd-s3-results-analysis.md` - Compile and analyze results
- ✅ `spike-prd-index.md` - Atomic PRD index with dependencies

---

## 📦 Prerequisites Checklist
Before starting PRD S.1, these must be in place:

### Required Configuration
- [ ] **Rails Project Setup** (eureka-homekit-rebuild)
  - Rails 8+ installed
  - PostgreSQL configured (if needed for future; not required for this spike)
  - `bundle install` completed
- [ ] **AiderDesk Running**
  ```bash
  # AiderDesk must be running on localhost:24337
  # Auth: admin:booberry
  aiderdesk start
  ```
- [ ] **ToolAdapter Configured**
  - Point to Claude 3.5 Sonnet API (primary) and Ollama (local fallback)
- [ ] **Gems for Task**
  ```ruby
  # Add to Gemfile
  gem 'httparty'
  group :test do
    gem 'webmock'
    gem 'rspec-rails'
  end
  ```

### Nice to Have
- [ ] RubyMine open with eureka-homekit-rebuild project
- [ ] OpenAI-compatible proxy for Grok (if testing Configuration 4)
- [ ] RuboCop configured for style checks

---

## 🎯 Implementation Order

### Phase 1: Setup (Sequential)
1. **PRD S.1**: Project Setup
   - Prepare eureka-homekit-rebuild for evaluations

### Phase 2: Execution (Parallel Tracks if possible)
2. **PRD S.2**: Evaluation Execution
   - Run AiderDesk in each configuration

### Phase 3: Analysis (Sequential)
3. **PRD S.3**: Results Analysis
   - Compile reports and insights

---

## 🔍 Key Design Decisions

### Evaluation Task (Prefab HTTP Client Service)
- Modeled after PRD 1.2 for realism: service-layer API client with error handling, config, URL encoding, full RSpec/WebMock tests
- Scoped to one service + one spec file for quick iterations
- No models/migrations to minimize setup
- Instructions emphasize Rails idioms, logging, and comprehensive testing

### AiderDesk Modes/Models
- Focused mode: Direct code gen
- Agent mode: Autonomous planning/handoffs
- Models: Claude 3.5 Sonnet (strong reasoning), Ollama (local efficiency), Grok fallback

### Isolation & Safety
- Use Git worktrees/branches per config to avoid contamination
- Human-in-loop: Junie reviews/logs but intervenes minimally
- No auto-commits/pushes

### Error Handling in Evaluations
- Log all pauses/clarifications
- Continue on partial failures (e.g., incomplete tests)
- Summarize deviations/hallucinations

---

## 🧪 Testing Strategy (for the Evaluation Task)

### Generated Code Checks
- Run `bundle install`
- Run `rspec spec/services/prefab_client_spec.rb`
- RuboCop on generated files

### Manual Review
- URL encoding with special chars
- Error logging
- ENV override
- Test coverage (success/failure/contexts)

### Spike-Level Success
- Reports for all configurations
- Insights on AiderDesk gaps (e.g., "Weak on URL encoding – needs RAG for examples")

---

## 📝 Implementation Commands

### PRD S.1: Project Setup
```bash
# Clone/setup eureka-homekit-rebuild if needed
git clone https://github.com/ericsmith66/eureka-homekit-rebuild.git
cd eureka-homekit-rebuild
bundle install

# Create spike branch
git checkout -b spike/aiderdesk-capability-baseline

# Start AiderDesk
aiderdesk start
```

### PRD S.2: Evaluation Execution
```bash
# For each config, create worktree
git worktree add ../spike-claude-focused spike/aiderdesk-capability-baseline
cd ../spike-claude-focused

# Run AiderDesk (example for focused + Claude)
aider --mode focused --model claude-3-5-sonnet

# Paste full task prompt
```

### PRD S.3: Results Analysis
- Manual: Compile logs into Markdown report
- Use code_execution tool if needed for aggregation

---

## ✅ Success Criteria
Spike Epic is complete when:
1. ✅ Project setup with clean environments per config
2. ✅ Evaluations run for at least 3 configurations (Claude focused/agent, Ollama focused)
3. ✅ Generated code tested (rspec pass rate ≥70% per run)
4. ✅ Full reports with pauses, quality assessments, merge recommendations
5. ✅ Analysis identifies 3–5 key insights (e.g., "Agent mode asks for clarification 2x more")
6. ✅ Recommendations for Epic 3 (e.g., "Prioritize context injection for error handling")
7. ✅ No destructive changes to main branch

---

## 📊 Total Scope

### PRDs (3)
- S.1: Setup (environment prep)
- S.2: Execution (runs + logging)
- S.3: Analysis (reporting + insights)

### Evaluation Task Scope
- 1 service class (PrefabClient)
- 4–5 methods
- 1 RSpec file (20+ specs)
- Gems: httparty, webmock, rspec-rails

### Outputs
- 3–4 evaluation branches
- Structured report per config
- Final spike summary

---

## 🎯 Current State

### ✅ SPIKE EPIC IN PROGRESS – UPDATED 2026-02-11
- ✅ Config 1 (Claude Focused): Success (19/19)
- ✅ Config 3 (Qwen 2.5-70B Focused): Success (14/14)
- ❌ Config 4 (Qwen 3 Next 80B Architect/Agent): Failed (Stability)
- 🔄 **NEW TARGETS**: qwen3:32b, qwen3:30b-a3b, qwen3-coder-next:latest (Configs 5-10)

### Test Summary (Expected for Generated Code)
- 20+ specs, 0 failures
- Covers success/failure/encoding/config

### Commits (Expected)
- Per config branch: Commit generated code + test results

---

## 🚀 Next Steps

### For Junie (AI Agent)
1. Review this spike epic document
2. Verify AiderDesk running on `localhost:24337`
3. Start with **PRD S.1** (Project Setup) on branch `spike/aiderdesk-capability-baseline`
4. Move to PRD S.2 (run configurations sequentially)
5. Commit logs/reports incrementally
6. Complete PRD S.3 for analysis

### For Eric (Developer)
1. Confirm eureka-homekit-rebuild accessible
2. Review spike task for any tweaks
3. Approve start
4. Review reports after each config

---

## 🔗 Dependencies

### External Services
- **AiderDesk**: Running on `localhost:24337` (auth: admin:booberry)
- **Prefab API**: Not required (use WebMock for tests)

### Internal Dependencies
- PRD S.2 depends on PRD S.1 (setup)
- PRD S.3 depends on PRD S.2 (results)

---

## ⏱️ Estimated Timeline
**With focused work:**
- PRD S.1: 30–60 min (setup)
- PRD S.2: 1–2 hours per config (runs)
- PRD S.3: 30–60 min (analysis)
**Total**: ~4–6 hours

---

## 📌 Important Notes

### Evaluation Task Rationale
- Modeled after PRD 1.2 for direct comparison
- Focus on service + tests to assess quality without overhead

### AiderDesk Setup Instructions
- In prompt, specify Rails 8+ stack
- Add gems: httparty (runtime), webmock/rspec-rails (test)
- Use `bundle add` if needed

### Reporting Format
- Markdown table for per-config summary
- Include code snippets for notable issues

**Last Updated**: 2026-02-10 15:45 CST
**Next Action**: Junie to start PRD S.1 setup

---

# Spike PRD Index

## Overview
Spike Epic broken into 3 atomic PRDs for focused execution.

## PRDs

### PRD S.1: Project Setup for Evaluation
**File**: `spike-prd-s1-project-setup.md`
**Status**: Ready
**Dependencies**: None
**Summary**: Prepare eureka-homekit-rebuild project, AiderDesk, and isolated environments for evaluations.

### PRD S.2: Evaluation Execution
**File**: `spike-prd-s2-evaluation-execution.md`
**Status**: Ready
**Dependencies**: S.1
**Summary**: Run AiderDesk in each configuration to implement the PrefabClient task, log interactions and results.

### PRD S.3: Results Analysis
**File**: `spike-prd-s3-results-analysis.md`
**Status**: Ready
**Dependencies**: S.2
**Summary**: Compile reports, analyze patterns, and generate insights/recommendations for Epic 3.

## Implementation Order
1. S.1 (Setup)
2. S.2 (Execution)
3. S.3 (Analysis)

**Spike Created**: 2026-02-10
**Last Updated**: 2026-02-10

---

# PRD S.1: Project Setup for Evaluation

## Spike Epic
Spike Epic: AiderDesk Capability Baseline Evaluation

## Objective
Prepare the eureka-homekit-rebuild project and environments for clean, isolated AiderDesk runs.

## Requirements

### Project Clone/Setup
- Clone `https://github.com/ericsmith66/eureka-homekit-rebuild.git` if not present
- `cd eureka-homekit-rebuild`
- `bundle install`
- `rails db:create db:migrate` (if needed)

### Branch/Worktree Setup
- Base branch: `spike/aiderdesk-capability-baseline`
- Create separate worktree for each config (e.g. `../spike-claude-focused`)

### AiderDesk Setup
- Start AiderDesk: `aiderdesk start`
- Verify API: curl `localhost:24337/api/settings` (auth admin:booberry)
- Configure ToolAdapter for Claude/Ollama/Grok

### Gems
- Add `httparty`, `webmock`, `rspec-rails`

## Success Criteria
- Project opens in RubyMine/terminal
- AiderDesk running and accessible
- Clean worktrees ready
- Gems installed

## Commands
```bash
git worktree add ../spike-claude-focused
bundle add httparty
bundle add webmock --group=test
bundle add rspec-rails --group=test
```

**Status**: Ready
**Depends On**: None
**Blocks**: S.2

---

# PRD S.2: Evaluation Execution

## Spike Epic
Spike Epic: AiderDesk Capability Baseline Evaluation

## Objective
Run AiderDesk in each configuration to implement the PrefabClient task, logging behavior and output.

## Requirements

### Configurations
1. Focused + Claude 3.5 Sonnet (✅ SUCCESS - 19/19)
2. Agent + Claude 3.5 Sonnet (❌ STALLED)
3. Focused + qwen2.5-70b (✅ SUCCESS - 14/14)
4. Architect/Agent + qwen3-next (80B) (❌ CRASHED)
5. Code Mode + qwen3:32b
6. Agent Mode + qwen3:32b
7. Code Mode + qwen3:30b-a3b
8. Agent Mode + qwen3:30b-a3b
9. Code Mode + qwen3-coder-next:latest
10. Agent Mode + qwen3-coder-next:latest
11. (Optional) Focused + Grok

### Execution Flow
- Enter worktree
- Start AiderDesk with mode/model
- Paste full task prompt
- Observe/log pauses
- After finish: run rspec, RuboCop

### Logging
- Time, pauses, interventions
- Test results

## Success Criteria
- All configs run
- Code/tests generated
- Logs complete

## Commands
```bash
aider --mode focused --model claude-3-5-sonnet
rspec spec/services/prefab_client_spec.rb
```

**Status**: Ready
**Depends On**: S.1
**Blocks**: S.3

---

# PRD S.3: Results Analysis

## Spike Epic
Spike Epic: AiderDesk Capability Baseline Evaluation

## Objective
Compile evaluation logs into reports and generate insights.

## Requirements

### Report Structure
- Table: Config, time, pauses, test pass %, quality notes, merge?
- Key insights (3–5)
- Recommendations for Epic 3

### Analysis
- Patterns in modes/models
- Gaps in context/memory

## Success Criteria
- Full report in Markdown
- Actionable insights

**Status**: Ready
**Depends On**: S.2
**Blocks**: None

---

This structure streamlines your workflow with Junie — she can implement PRD by PRD, just like Epic 1.

Let me know if you'd like any adjustments or to hand off directly! 🚀