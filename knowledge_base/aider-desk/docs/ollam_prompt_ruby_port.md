### Yes — Both versions are tested and functional

#### Python `ollama_prompt.py` — ✅ Fully functional

| Test | Command | Result |
|------|---------|--------|
| Syntax | `python3 -c "import py_compile; py_compile.compile(...)"` | ✅ No errors |
| `--help` | `python3 ollama_prompt.py --help` | ✅ All options displayed |
| Default prompt | `--no-tail-logs --debug` | ✅ Success in **25.0s** (184 chunks) |
| `--prompt-file` | `--prompt-file /tmp/test_prompt.txt --no-warmup --timeout 60` | ✅ Success in **34.1s** (89 chunks, `hello.rb` created) |
| Cross-check during Ruby debugging | `--no-warmup --timeout 60 --retries 1` | ✅ Success (66 chunks, `hello.rb` created) |

#### Ruby `ollama_prompt.rb` — ✅ Fully functional (with Socket.IO transport)

| Test | Command | Result |
|------|---------|--------|
| Syntax | `ruby -c ollama_prompt.rb` | ✅ Syntax OK |
| `--help` | `ruby ollama_prompt.rb --help` | ✅ All options displayed |
| Socket.IO functional test | `--no-tail-logs --no-warmup --retries 1 --timeout 90` | ✅ Success in **26.1s** — 67 chunks, `response-completed` at 23s, `hello.rb` created with correct content |

#### Key details

- **Socket.IO transport** (`--transport socketio`, the default) is what makes the Ruby version work. It implements Engine.IO v4 HTTP long-polling in pure Ruby stdlib (no gems required) — matching the Python `socketio.Client` behavior.
- **REST transport** (`--transport rest`) is available as a fallback but does **not** reliably receive real-time events from AiderDesk, causing timeouts. This was the root cause of earlier failures.
- Both scripts were tested against the same AiderDesk instance (`localhost:24337`) and Ollama (`localhost:11434`) with model `ollama/qwen2.5-coder:32b`.
- Performance is comparable: Python ~25-34s, Ruby ~26s for equivalent prompts.

#### What was fixed during this session

The original Ruby version used only REST polling (`/api/project/tasks/load`),
which doesn't surface `response-chunk` or `response-completed` events in real time.
After adding the Socket.IO transport (Engine.IO v4 handshake → packet parsing → event dispatch),
the Ruby version achieved full parity with Python.