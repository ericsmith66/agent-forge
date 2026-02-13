### Spike Findings: LLM Constraints and AiderDesk Configuration

#### 1. LLM Capability & Constraint Findings
*   **Model Comparison:** `qwen3-coder-next:latest` (via Ollama) demonstrated superior adherence to complex technical constraints compared to `Claude-3.5-Sonnet` when provided with high-pressure directives.
*   **The "Strict Directive" Effect:** Qwen's compliance jumped from 60% to 95% after adding the **STRICT EXECUTION DIRECTIVE – READ THIS FIRST – ZERO DEVIATION ALLOWED** and **Non-Negotiable Constraints** blocks.
*   **Testing & Debugging Performance:** While Qwen is highly compliant, it is less "efficient" in the final 10% of tasks (testing/debugging), often entering long "Fix + rerun loops" (~40 minutes of a 56-minute run).
*   **Path of Least Resistance:** Both models tend to "drift" toward easier but less secure or less compliant implementations (e.g., using backticks instead of `Open3`) unless explicitly forbidden.

#### 2. AiderDesk Configuration Discovery
*   **Configuration Invisibility:** During the spike, it was discovered that `aider_desk` was **not observing** certain skillset or agent files.
*   **Root Cause - Nesting:** The issue was caused by `.aider-desk` directories being nested (e.g., `.aider-desk/agents/rails-debug/agents/...` or similar). AiderDesk expects a flat or specific hierarchical structure that was being violated by redundant symlinks or incorrect directory creation.
*   **Agent vs. Sub-Agent Requirement:** The current `ror-agent-forge-config` assumes a flat list of agents. However, real-world usage clearly calls for **Agents and Sub-Agents** (hierarchical profiles).
    *   *Example:* `rails` (Agent) -> `debug`, `refactor`, `ui` (Sub-Agents).
*   **Skillset Observation:** Skills were also being missed due to incorrect path resolution when the `.aider-desk` directory itself was a symlink or contained nested symlinks.

#### 3. Required Changes to `ror-agent-forge-config`
*   **Restructure for Hierarchy:** Move from a flat `agents/` directory to a structured one that supports parent-child relationships between profiles.
*   **Standardize Constraint Injection:** Incorporate the "Strict Execution Directive" as a default rule or template within the `ror-agent-forge-config` to ensure all agents benefit from this high-compliance prompting style.
    *   *Finding:* The **STRICT EXECUTION DIRECTIVE** is a non-negotiable prerequisite for model stability and must be accessible as a shared skill or global rule.
*   **Flat Skill Resolution:** Ensure `skills/` are organized in a way that AiderDesk can reliably discover them regardless of the project's symlink depth.

#### 4. Implications for Implementation
*   **Dynamic Rule Merging:** The discovery that nesting breaks observation means our `bin/setup-aider-desk` script must be extremely precise about directory structure.
*   **Agent Profiles as "Presets":** We should treat the top-level agents in `ror-agent-forge-config` as "Family" templates (e.g., Rails) and sub-agents as "Task" specializations.
