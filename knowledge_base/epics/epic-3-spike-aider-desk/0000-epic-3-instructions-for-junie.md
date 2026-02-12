**Log Requirements**
- Junie: read the Junie log requirement doc and create/update a task log under `knowledge_base/prds-junie-log/`.
- In the log, include detailed manual test steps and expected results.
- If asked to review: create a separate document named `PRD-1-01-local-setup-verification-feedback-V{{N}}.md` in the same directory.


**Junie – Summary of your responsibilities in the AiderDesk Capability Baseline Spike**

Hi Junie,

We are running a **time-boxed spike** to evaluate how well AiderDesk performs when implementing a realistic Rails service task. The goal is to baseline its code quality, test coverage, Rails idioms, error handling, and interaction behavior (pauses, clarifications, context retention) across different modes and models.

This spike will directly inform how much context/memory support we need to build in Epic 3.

### Your overall mission
You are the **execution and observation agent** for this evaluation. You will:
1. Prepare the project environment
2. Run AiderDesk in multiple configurations
3. Observe and log every interaction without over-helping
4. Test the generated code
5. Compile structured reports so we can analyze AiderDesk’s strengths and gaps

### What you need to do – step by step

1. **PRD S.1 – Project Setup**
    - Go to the **eureka-homekit-rebuild** project
    - Make sure it’s on a clean branch: `spike/aiderdesk-capability-baseline`
    - Run `bundle install`
    - Add required gems if missing:
      ```ruby
      gem 'httparty'
      group :test do
        gem 'webmock'
        gem 'rspec-rails'
      end
      ```
    - Create separate worktrees or branches for each configuration (recommended: `spike-claude-focused`, `spike-claude-agent`, `spike-ollama-focused`, etc.)
    - Confirm AiderDesk is running on `localhost:24337` (auth: admin:booberry)

2. **PRD S.2 – Evaluation Execution**  
   Run **each configuration separately** in its own worktree/branch:

   Configurations to test:
    - Config 1: **Focused code mode** + **Claude 3.5 Sonnet** (✅ SUCCESS)
    - Config 2: **Agent mode** + **Claude 3.5 Sonnet** (❌ STALLED)
    - Config 3: **Focused code mode** + **qwen2.5-70b** (✅ SUCCESS)
    - Config 4: **Architect/Agent mode** + **qwen3-next (80B)** (❌ CRASHED)
    - **Config 5: Code Mode + qwen3:32b**
    - **Config 6: Agent Mode + qwen3:32b**
    - **Config 7: Code Mode + qwen3:30b-a3b**
    - **Config 8: Agent Mode + qwen3:30b-a3b**
    - **Config 9: Code Mode + qwen3-coder-next:latest**
    - **Config 10: Agent Mode + qwen3-coder-next:latest**

   For each run:
    - Start AiderDesk in the correct mode/model.
    - **Note**: For local Ollama runs, prefer using `python3 knowledge_base/aider-desk/docs/ollama_prompt.py` for more robust error detection and warm-ups.
    - Example: `python3 knowledge_base/aider-desk/docs/ollama_prompt.py --model ollama/qwen3:32b --mode code --prompt-file knowledge_base/epics/epic-3-spike-aider-desk/prefab_client_greenfield.txt`
    - Let AiderDesk work until it says it’s done or explicitly asks for clarification.
    - **Do NOT proactively give hints** — only respond if it gets truly stuck (and log every time you intervene)
    - After it finishes:
        - Run `bundle install` if needed
        - Run `rspec spec/services/prefab_client_spec.rb`
        - Run RuboCop if configured
        - Save the generated files (prefab_client.rb and prefab_client_spec.rb)

3. **PRD S.3 – Results Analysis & Reporting**  
   For **each configuration**, produce a short structured report:

   ```markdown
   ## Configuration: Focused + Claude 3.5 Sonnet

   - Time taken: XX minutes
   - Number of pauses/clarifications: X (list topics)
   - Interventions by you: X (list what you had to clarify)
   - RSpec result: [passed / X failures] (paste summary)
   - RuboCop: [clean / X offenses]
   - URL encoding handled correctly? Yes/No
   - Logging on error implemented? Yes/No
   - Test coverage quality: (good/partial/weak – comment on contexts)
   - Rails idioms & style: (notes)
   - Would you merge this code as-is? Yes/No + why
   - Key observations: (e.g. hallucinations, creative additions, weaknesses)
   ```

   After all runs:
    - Compile a final summary report:
        - Patterns across modes/models
        - 3–5 key insights (e.g. "Agent mode asks 2x more questions", "Ollama struggles with WebMock stubs")
        - Recommendations for Epic 3 (e.g. "Prioritize context injection for error handling examples")

### Important rules for you during this spike
- Stay passive — let AiderDesk show its natural behavior
- Log **everything** (especially pauses and your responses)
- Do not fix code unless AiderDesk completely stalls
- Keep each config isolated (separate branches/worktrees)
- Aim to finish all runs and reports in 1–2 days

Start with **PRD S.1 (setup)** right now.  
Once setup is confirmed, move to **PRD S.2** and begin with Config 1 (Claude focused mode).

Let me know when setup is done or if you hit any blockers.

Thanks, Junie — this is critical data for our agent-forge roadmap.

---

You can copy-paste this summary directly to Junie.

If you want me to expand any PRD into full detail (e.g. the exact task prompt text for PRD S.2), add more logging fields, or adjust anything before handing off, just say the word.

Otherwise, you're ready to kick it off! 🚀