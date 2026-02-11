## Created `knowledge_base/ollama_prompt.py` — General-Purpose AiderDesk + Ollama Prompt Runner

Converted `test_ollama_submission.py` into a new CLI-driven script with all recommended improvements:

### CLI Arguments
- `--prompt` / `-p` — Custom prompt text (default: calculate_pi.rb demo)
- `--model` / `-m` — Model identifier (default: `ollama/qwen2.5-coder:32b`)
- `--timeout` / `-t` — Per-attempt timeout in seconds (default: 120)
- `--retries` / `-r` — Max retry attempts (default: 3)
- `--debug` / `-d` — Verbose debug output
- `--mode` — Aider prompt mode: `code`, `agent`, `ask`, `architect`
- `--edit-format` — Edit format: `diff`, `whole`, `udiff`, `editor-diff`, `editor-whole`
- `--base-url`, `--ollama-url`, `--username`, `--password`, `--project-dir`, `--target-file`
- `--no-warmup`, `--no-cleanup`, `--no-tail-logs`, `--warmup-timeout`

### Improvements Incorporated (all 8 priorities from the issue)

**🔴 Priority 1 — Ollama warm-up:** `warm_up_ollama()` sends a trivial "hi" prompt with `keep_alive: 24h` before any task, eliminating cold-start zombies.

**🔴 Priority 2 — Keep-alive:** Warm-up request includes `"keep_alive": "24h"` to prevent model unloading.

**🟡 Priority 3 — Edit format:** `--edit-format whole` CLI flag sets format at project level via `/project/settings/edit-formats`.

**🟡 Priority 4 — Health checks:** `check_ollama_health()` verifies Ollama is running and model is pulled; `check_ollama_running_models()` shows loaded models at each attempt start and on failure.

**🟡 Priority 5 — Structured error classification:** `FailureReason` class with `classify_failure()` replaces generic "zombie" with: `cold_start`, `partial`, `question`, `connection`, `ollama_error`, `unknown`.

**🟢 Priority 6 — Ollama error pattern detection:** Log tailer matches patterns like "out of memory", "CUDA", "failed to load", "context length exceeded" and flags them as `OLLAMA-ERR`.

**🟢 Priority 7 — Per-phase timing:** Tracks and reports timing for: `aiderdesk_health`, `ollama_health`, `warm_up`, `setup`, `task_creation`, `first_chunk`, `file_on_disk`, `completion`.

**🟢 Priority 8 — Simplified prompt + agent mode:** Default prompt simplified; `--mode agent` available via CLI.

### Additional improvements
- Auto-approve set at project level (not just task level)
- Stale-chunk detection (30s with no new chunks → warning)
- All hardcoded globals replaced with CLI arguments
- Debug-level logging gated behind `--debug` flag

### Changes to `knowledge_base/ollama_prompt.py`

#### New `--prompt-file` / `-f` CLI argument
- Added `--prompt-file` (`-f`) argument that accepts a path to a file containing prompt text
- When specified, it overrides the `--prompt` argument
- Supports both absolute and relative paths (relative paths are resolved to absolute)
- Validates the file exists and is non-empty before proceeding
- Logs the loaded file path and character count

#### Python-only component documentation for Ruby port
Added inline documentation comments throughout the codebase marking which components are Python-specific and their Ruby equivalents:

- **Module docstring**: Added a comprehensive mapping table of all Python dependencies → Ruby equivalents (argparse → OptionParser, requests → Net::HTTP/Faraday, socketio → socketio-client gem, threading → Thread, etc.)
- **Import section**: Each import annotated with its Ruby equivalent
- **Timestamp/logging**: Marked as PORTABLE with Ruby `Time.now.strftime` equivalent
- **FailureReason/classify_failure**: Marked as PORTABLE (pure data + logic)
- **Ollama health & warm-up**: Marked as PYTHON-ONLY (requests library)
- **API helpers**: Marked as PYTHON-ONLY (requests + HTTPBasicAuth)
- **Background prompt sender**: Marked as PYTHON-ONLY (threading.Thread → Ruby Thread.new)
- **Log file tailer**: Marked as PYTHON-ONLY (threading.Thread + Event → Ruby Thread + IO#gets)
- **EventMonitor**: Marked as PYTHON-ONLY (python-socketio → socketio-client gem; threading.Event → Mutex + ConditionVariable)
- **CLI parsing**: Marked as PYTHON-ONLY (argparse → OptionParser/Thor)
- **main()**: Marked as PORTABLE (orchestration logic is language-agnostic)
