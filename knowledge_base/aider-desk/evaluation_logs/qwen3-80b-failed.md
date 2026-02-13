# Evaluation Log: Qwen 3 Next 80B A3B Thinking (Evaluation Failure)

## Configuration
- **Model**: `ollama/qwen3-next:latest` (80B A3B Thinking)
- **AiderDesk Version**: Latest (configured with qwen3 support)
- **Mode(s) Tested**: Architect, Code, Memory-Augmented Agent
- **Infrastructure**: m3ultra (128GB RAM), Ollama local

## Summary of Results
| Track | Mode | Result | Pass Rate | Time | Key Issue |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Track A (Architect)** | Architect | **CRASH** | 0% | ~7m | Ollama 500 / Timeout during thinking |
| **Track A (Code)** | Code | **CRASH** | 0% | ~7m | Ollama 500 / Timeout during thinking |
| **Track B (Agent)** | Agent | **STALL** | 0% | ~2m | Model identity confusion / Tool schema error |

## Key Findings

### 1. Extreme Latency & Internal Crashes
The "Thinking" model (80B) consistently exceeded the 300s-600s latency window. In multiple attempts, it hit the 300s read timeout, and when extended to 1200s, it eventually crashed with a 500 error from the Ollama server after ~400s of processing.
- **Observation**: The model spends too much time in the "thinking" phase, which currently causes the AiderDesk <-> Ollama connection to drop or the model runner to fail.

### 2. Agent Mode Incompatibility
The model frequently identifies itself as `llama3.1:70b` in internal reasoning steps, leading to confusion in the agent loop. Furthermore, it failed to adhere to the tool schema (e.g., providing a string for a number field), causing immediate validation errors in AiderDesk's agent engine.

### 3. Comparison with Qwen 2.5-70B
- **Qwen 2.5-70B (Focused)**: Successfully implemented the task with 14/14 specs passing in ~15 minutes.
- **Qwen 3-80B**: Produced zero code artifacts. It is currently "too heavy" for the existing AiderDesk integration logic without significant timeout and streaming adjustments.

## Recommendations for Epic 3
- **Local Model Constraints**: Do not use "Thinking" models (like Qwen3-80B) for multi-file implementation tasks until Ollama streaming/timeout issues are resolved. 
- **Architect Separation**: If using heavy models, restrict them to the **Architect** (design-only) phase with a very high timeout (15m+), and use a faster model (like Qwen 2.5-Coder or Claude) for the implementation turn.
- **Reliability over "Intelligence"**: For the baseline capability, Qwen 2.5-70B or Sonnet 3.5 remain the recommended models for autonomous development in AiderDesk.

**STATUS**: FAILURE - Model unstable for current toolchain.
