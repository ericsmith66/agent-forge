# Spike Results: AiderDesk Capability Baseline Evaluation (Set 6)
Date: 2026-02-11
Version: V1
Reviewer: Junie

## 1. Executive Summary
Evaluation of the new `qwen3-next` (80B A3B Thinking) model across Architect and Agent modes.

**Key Takeaway:** The 80B "Thinking" model is currently too slow/unstable for the AiderDesk + Ollama toolchain in autonomous modes. It consistently hits timeouts or crashes the Ollama server during long reasoning periods.

---

## 2. Configuration Analysis

| Metric | Config 6a: Architect + Qwen 3 Next 80B | Config 6b: Agent + Qwen 3 Next 80B |
| :--- | :--- | :--- |
| **Status** | ❌ **FAILED (Timeout/Crash)** | ❌ **FAILED (Stalled/Schema Error)** |
| **Time taken** | >15 minutes (Aborted) | ~10 minutes (Aborted) |
| **RSpec Pass Rate** | 0% (No code written) | 0% (No code written) |
| **Pauses** | Persistent HTTP 504/500 | 2 (Schema validation errors) |
| **Interventions** | N/A | 1 (Clarifying tool usage) |
| **Merge?** | **No** | **No** |

---

## 3. Detailed Findings

### A. "Thinking" Latency & Timeouts
The Qwen 3 Next 80B model uses a "Thinking" process that can take minutes before outputting a response.
- **Issue:** AiderDesk's default timeouts (and the ToolAdapter's polling) are not tuned for 5-10 minute pauses.
- **Observation:** Even with 1200s timeouts, the Ollama server eventually failed with a 500 error after ~7 minutes of sustained high load.

### B. Tool Schema Instability
In Agent mode, the model struggled with strict tool calling.
- **Issue:** It passed strings to parameters expecting numbers and occasionally hallucinated its own identity (identifying as `llama3.1:70b`).
- **Observation:** The reasoning loops often became circular, performing semantic searches that yielded no results and then repeating them.

### C. Resource Exhaustion
Running an 80B model with active tool-calling loops on an M3 Ultra is possible but pushes the current AiderDesk/Python bridge to its limits, leading to gateway timeouts.

---

## 4. Recommendations
1. **Model Tiering**: Use Qwen 3 Next 80B only for high-level **Architect** turns where "Thinking" time is expected, and hand off implementation to **Qwen 2.5-70B**.
2. **Timeout Refactoring**: Implement a more robust heartbeat or streaming detection for models that "think" silently for long periods.
3. **Agent Profile Tuning**: Stricter system prompts are needed to prevent Qwen 3 from drifting into circular planning.

---
