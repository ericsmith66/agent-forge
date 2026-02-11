#!/usr/bin/env python3
"""
General-purpose AiderDesk + Ollama prompt runner with CLI arguments.

Converted from test_ollama_submission.py with comprehensive improvements:
- Ollama health check and model warm-up (eliminates cold-start zombies)
- Structured error classification (replaces generic "zombie" diagnosis)
- Stale-chunk detection and per-phase timing metrics
- Ollama error pattern detection in log tailer
- Configurable via CLI: prompt, model, debug level, retries, timeout, edit format, mode
- Optional --prompt-file to load prompt text from a file

Usage:
    python3 knowledge_base/ollama_prompt.py --prompt "Create hello.rb that prints hello world"
    python3 knowledge_base/ollama_prompt.py --prompt-file my_prompt.txt
    python3 knowledge_base/ollama_prompt.py --model ollama/qwen2.5-coder:32b --timeout 180 --retries 5
    python3 knowledge_base/ollama_prompt.py --debug --edit-format whole --mode agent

Prerequisites:
    - AiderDesk running on localhost:24337
    - Ollama running with the target model pulled
    - pip install requests python-socketio[client]

Python-only components (must be re-implemented for Ruby port):
    - argparse (CLI parsing)        → Ruby: OptionParser or Thor gem
    - requests (HTTP client)         → Ruby: Net::HTTP, Faraday, or HTTParty gem
    - python-socketio (Socket.IO)    → Ruby: socketio-client or faye-websocket gem
    - threading.Thread (concurrency) → Ruby: Thread class (built-in)
    - threading.Event (signalling)   → Ruby: use Mutex + ConditionVariable or Queue
    - base64 (encoding)              → Ruby: Base64 module (stdlib)
    - json (serialisation)           → Ruby: JSON module (stdlib)
    - os.path (file operations)      → Ruby: File, Dir, Pathname (stdlib)
    - datetime (timestamps)          → Ruby: Time class (built-in)
"""

# ── Python-only: standard library imports ───────────────────────────────────
# Ruby equivalents noted inline for future port.
import argparse          # Ruby: OptionParser (stdlib) or Thor gem
import base64            # Ruby: Base64 (stdlib)
import json              # Ruby: JSON (stdlib)
import os                # Ruby: File, Dir, Pathname (stdlib)
import sys               # Ruby: $stdout, $stderr, exit()
import threading         # Ruby: Thread, Mutex, ConditionVariable (built-in)
import time              # Ruby: Time.now, sleep()
from datetime import datetime  # Ruby: Time.now.strftime

# ── Python-only: third-party dependencies ────────────────────────────────────
# These must be installed via pip; Ruby equivalents noted.
import requests                    # Ruby: Net::HTTP (stdlib), Faraday, or HTTParty gem
from requests.auth import HTTPBasicAuth  # Ruby: Net::HTTP basic_auth or Faraday middleware
import socketio                    # Ruby: socketio-client gem or faye-websocket gem


# ── Globals (set from CLI args in main) ──────────────────────────────────────

DEBUG = False


# ── Timestamp / logging ─────────────────────────────────────────────────────
# PORTABLE: These are simple string formatting + print functions.
# Ruby: Time.now.strftime("%Y-%m-%dT%H:%M:%S.%L") and puts/STDOUT.flush

def ts():
    """ISO-8601 timestamp for log cross-referencing with AiderDesk logs."""
    return datetime.now().strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3]


def log(level, msg):
    """Print a timestamped log line. DEBUG-level lines are suppressed unless --debug."""
    if level == "DEBUG" and not DEBUG:
        return
    print(f"{ts()} [{level}] {msg}", flush=True)


# ── Failure classification ───────────────────────────────────────────────────
# PORTABLE: Pure data + logic, no Python-specific dependencies.
# Ruby: use a module with constants or a simple class with class methods.

class FailureReason:
    COLD_START = "cold_start"
    PARTIAL_RESPONSE = "partial"
    QUESTION_UNANSWERED = "question"
    CONNECTION_ERROR = "connection"
    OLLAMA_ERROR = "ollama_error"
    UNKNOWN = "unknown"


def classify_failure(monitor, prompt_result, elapsed):
    """Return a structured failure reason instead of generic 'zombie'."""
    if monitor.chunks_received == 0:
        if elapsed > 60:
            return FailureReason.COLD_START
        return FailureReason.CONNECTION_ERROR

    if monitor.question_pending.is_set():
        return FailureReason.QUESTION_UNANSWERED

    if prompt_result.get("error"):
        error_str = str(prompt_result["error"]).lower()
        if "timeout" in error_str or "connection" in error_str:
            return FailureReason.CONNECTION_ERROR
        return FailureReason.OLLAMA_ERROR

    if monitor.chunks_received > 0:
        return FailureReason.PARTIAL_RESPONSE

    return FailureReason.UNKNOWN


# ── Ollama health & warm-up ─────────────────────────────────────────────────
# PYTHON-ONLY: Uses requests library for HTTP calls.
# Ruby: replace requests.get/post with Net::HTTP or Faraday equivalents.

def check_ollama_health(model="qwen2.5-coder:32b", ollama_url="http://localhost:11434"):
    """Verify Ollama is running and the model is available."""
    try:
        r = requests.get(f"{ollama_url}/api/tags", timeout=5)
        if r.status_code != 200:
            log("FAIL", f"Ollama not responding: HTTP {r.status_code}")
            return False

        models = [m["name"] for m in r.json().get("models", [])]
        short_model = model.replace("ollama/", "")
        if not any(short_model in m for m in models):
            log("FAIL", f"Model {short_model} not found. Available: {models}")
            return False

        log("PASS", f"Ollama healthy, model {short_model} available")
        return True
    except Exception as e:
        log("FAIL", f"Cannot reach Ollama: {e}")
        return False


def check_ollama_running_models(ollama_url="http://localhost:11434"):
    """Check what models Ollama currently has loaded."""
    try:
        r = requests.get(f"{ollama_url}/api/ps", timeout=5)
        if r.status_code == 200:
            models = r.json().get("models", [])
            for m in models:
                log("OLLAMA", f"  Loaded: {m['name']} (size={m.get('size', '?')}, "
                              f"expires={m.get('expires_at', '?')})")
            return models
        return []
    except Exception:
        return []


def warm_up_ollama(model="qwen2.5-coder:32b", timeout=300, ollama_url="http://localhost:11434"):
    """Send a trivial prompt to force model loading into memory."""
    short_model = model.replace("ollama/", "")
    log("INFO", f"Warming up Ollama model: {short_model} (may take several minutes)...")
    try:
        r = requests.post(
            f"{ollama_url}/api/generate",
            json={
                "model": short_model,
                "prompt": "hi",
                "stream": False,
                "keep_alive": "24h",
            },
            timeout=timeout,
        )
        if r.status_code == 200:
            log("PASS", f"Model {short_model} is warm and ready")
            return True
        else:
            log("WARN", f"Warm-up returned {r.status_code}: {r.text[:200]}")
            return False
    except requests.exceptions.Timeout:
        log("WARN", f"Warm-up timed out after {timeout}s — model may still be loading")
        return False
    except Exception as e:
        log("WARN", f"Warm-up failed: {e}")
        return False


# ── AiderDesk API helpers ────────────────────────────────────────────────────
# PYTHON-ONLY: Uses requests library with HTTPBasicAuth.
# Ruby: use Net::HTTP with req.basic_auth(user, pass), or Faraday basic_auth.

def api_get(api_url, auth, path, **kwargs):
    url = f"{api_url}{path}"
    log("DEBUG", f"GET  {url}")
    r = requests.get(url, auth=auth, timeout=30, **kwargs)
    log("DEBUG", f"  -> {r.status_code} ({len(r.content)}B)")
    return r


def api_post(api_url, auth, path, payload=None, timeout=30, **kwargs):
    url = f"{api_url}{path}"
    body_preview = json.dumps(payload, separators=(',', ':'))[:200] if payload else "null"
    log("DEBUG", f"POST {url}  body={body_preview}")
    r = requests.post(url, auth=auth, json=payload, timeout=timeout, **kwargs)
    log("DEBUG", f"  -> {r.status_code} ({len(r.content)}B)")
    return r


def health_check(api_url, auth):
    try:
        r = requests.get(f"{api_url}/settings", auth=auth, timeout=5)
        return r.status_code == 200
    except Exception:
        return False


# ── Background prompt sender ────────────────────────────────────────────────
# PYTHON-ONLY: Uses threading.Thread for async HTTP call.
# Ruby: use Thread.new { ... } with a shared hash/struct for the result.

def fire_prompt_async(api_url, auth, project_dir, task_id, prompt, mode="code"):
    """Fire run-prompt in a background thread. Returns a dict holding the result."""
    result = {"status": None, "error": None, "done": False}

    def _run():
        try:
            r = requests.post(
                f"{api_url}/run-prompt",
                auth=auth,
                json={
                    "projectDir": project_dir,
                    "taskId": task_id,
                    "prompt": prompt,
                    "mode": mode,
                },
                timeout=300,
            )
            result["status"] = r.status_code
        except Exception as e:
            result["error"] = str(e)
        finally:
            result["done"] = True

    t = threading.Thread(target=_run, daemon=True)
    t.start()
    log("INFO", f"run-prompt fired in background thread (tid={t.ident})")
    return result, t


# ── Log file tailer ─────────────────────────────────────────────────────────
# PYTHON-ONLY: Uses threading.Thread + threading.Event for background file tailing.
# Ruby: use Thread.new with File.open and IO#gets in a loop; signal via Queue or flag.

OLLAMA_ERROR_PATTERNS = [
    "error",
    "out of memory",
    "cuda",
    "failed to load",
    "context length exceeded",
    "connection refused",
]


def start_log_tailer(log_path, label):
    """Start a background thread that tails a log file and prints new lines."""
    stop_event = threading.Event()

    def _tail():
        if not os.path.exists(log_path):
            log("WARN", f"{label} log not found at {log_path} — tailing disabled")
            return
        try:
            with open(log_path, "r") as f:
                f.seek(0, 2)
                while not stop_event.is_set():
                    line = f.readline()
                    if line:
                        line = line.rstrip()
                        if line:
                            # Detect Ollama errors in log lines
                            if label == "OLLAMA" and any(
                                p in line.lower() for p in OLLAMA_ERROR_PATTERNS
                            ):
                                log("OLLAMA-ERR", f"⚠️  {line}")
                            else:
                                log(label, line)
                    else:
                        stop_event.wait(0.5)
        except Exception as e:
            log("WARN", f"{label} log tailer error: {e}")

    t = threading.Thread(target=_tail, daemon=True)
    t.start()
    return stop_event


# ── Socket.IO event monitor ─────────────────────────────────────────────────

STALE_CHUNK_TIMEOUT = 30  # seconds with no new chunks


# PYTHON-ONLY: Uses python-socketio for real-time event monitoring.
# Ruby: use the socketio-client gem, or faye-websocket + manual event-type dispatch.
# The threading.Event objects used for signalling should become Mutex + ConditionVariable
# or a simple Queue-based flag in the Ruby version.

class EventMonitor:
    """
    Connects to AiderDesk via Socket.IO and subscribes to real-time events.
    Tracks response-completed, ask-question, response-chunk, log, and tool events.
    """

    def __init__(self, task_id, base_url, project_dir):
        self.task_id = task_id
        self.base_url = base_url
        self.project_dir = project_dir
        self.completed = threading.Event()
        self.question_pending = threading.Event()
        self.question_text = None
        self.file_dropped = False
        self.chunks_received = 0
        self.last_activity = time.time()
        self.sio = socketio.Client(logger=False, engineio_logger=False)
        self._setup_handlers()

    def _setup_handlers(self):
        @self.sio.on('connect')
        def on_connect():
            log("SIO", "✅ Connected to AiderDesk Socket.IO")
            self.sio.emit('message', {
                'action': 'subscribe-events',
                'eventTypes': [
                    'response-chunk',
                    'response-completed',
                    'ask-question',
                    'question-answered',
                    'user-message',
                    'log',
                    'tool',
                    'context-files-updated',
                    'task-completed',
                    'task-cancelled',
                ],
                'baseDirs': [self.project_dir],
            })
            log("SIO", f"Subscribed to events for {self.project_dir}")

        @self.sio.on('disconnect')
        def on_disconnect():
            log("SIO", "Disconnected from AiderDesk Socket.IO")

        @self.sio.on('event')
        def on_event(payload):
            event_type = payload.get('type', 'unknown')
            data = payload.get('data', {})
            event_task = data.get('taskId', '')

            if event_task and event_task != self.task_id:
                return

            self.last_activity = time.time()

            if event_type == 'response-chunk':
                self.chunks_received += 1
                content = str(data.get('content') or data.get('chunk') or '')
                if self.chunks_received <= 5 or self.chunks_received % 20 == 0:
                    preview = (content[:100] + '...') if len(content) > 100 else content
                    log("SIO", f"  [chunk #{self.chunks_received}] {preview}")

                if 'dropping' in content.lower():
                    self.file_dropped = True
                    log("DETECT", "⚠️  Aider dropped a file from chat context")

            elif event_type == 'response-completed':
                content = str(data.get('content') or '')
                preview = (content[:150] + '...') if len(content) > 150 else content
                log("SIO", f"  ✅ [response-completed] {preview}")
                self.completed.set()

            elif event_type == 'ask-question':
                q = data.get('question') or data.get('content') or str(data)
                q_text = str(q)[:200]
                self.question_text = q_text
                self.question_pending.set()
                log("SIO", f"  ❓ [ask-question] {q_text}")

            elif event_type == 'question-answered':
                log("SIO", "  [question-answered]")
                self.question_pending.clear()

            elif event_type == 'log':
                content = str(data.get('content') or data.get('message') or '')
                level = data.get('level', 'info')
                preview = (content[:120] + '...') if len(content) > 120 else content
                log("SIO", f"  [log/{level}] {preview}")

                if 'dropping' in content.lower():
                    self.file_dropped = True
                    log("DETECT", "⚠️  Aider dropped a file from chat context")

            elif event_type == 'tool':
                content = str(data.get('content') or '')
                preview = (content[:120] + '...') if len(content) > 120 else content
                log("SIO", f"  [tool] {preview}")

            elif event_type == 'user-message':
                content = str(data.get('content') or '')
                preview = (content[:120] + '...') if len(content) > 120 else content
                log("SIO", f"  [user-message] {preview}")

            elif event_type in ('task-completed', 'task-cancelled'):
                log("SIO", f"  [{event_type}]")
                self.completed.set()

            elif event_type == 'context-files-updated':
                files = data.get('files', [])
                log("SIO", f"  [context-files-updated] {len(files)} file(s)")

            else:
                log("DEBUG", f"  [{event_type}] (unhandled)")

    def connect(self, username, password):
        """Connect to AiderDesk Socket.IO server."""
        creds = base64.b64encode(f"{username}:{password}".encode()).decode()
        try:
            self.sio.connect(
                self.base_url,
                headers={"Authorization": f"Basic {creds}"},
                wait_timeout=10,
            )
            return True
        except Exception as e:
            log("SIO", f"❌ Connection failed: {e}")
            return False

    def disconnect(self):
        try:
            self.sio.disconnect()
        except Exception:
            pass

    def update_task_id(self, new_task_id):
        """Update the task ID filter (for retry attempts with new tasks)."""
        self.task_id = new_task_id
        self.completed.clear()
        self.question_pending.clear()
        self.question_text = None
        self.file_dropped = False
        self.chunks_received = 0
        self.last_activity = time.time()


# ── CLI argument parsing ─────────────────────────────────────────────────────
# PYTHON-ONLY: Uses argparse for CLI parsing.
# Ruby: use OptionParser (stdlib) or the Thor gem for an equivalent CLI interface.

def parse_args():
    parser = argparse.ArgumentParser(
        description="General-purpose AiderDesk + Ollama prompt runner",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""\
Examples:
  %(prog)s --prompt "Create hello.rb that prints hello world"
  %(prog)s --prompt-file my_prompt.txt
  %(prog)s --model ollama/qwen2.5-coder:32b --timeout 180 --retries 5
  %(prog)s --debug --edit-format whole --mode agent
  %(prog)s --prompt "Fix the bug in app.py" --no-warmup --no-cleanup
""",
    )

    # Required / core
    parser.add_argument(
        "--prompt", "-p",
        default=(
            "Create a single file called calculate_pi.rb that calculates Pi to N "
            "decimal places, where N is passed as a command-line argument. "
            "Keep it simple — under 20 lines."
        ),
        help="The prompt to send to AiderDesk (default: calculate_pi.rb demo)",
    )
    parser.add_argument(
        "--prompt-file", "-f",
        default=None,
        help="Path to a file containing the prompt text. Overrides --prompt if set.",
    )
    parser.add_argument(
        "--model", "-m",
        default="ollama/qwen2.5-coder:32b",
        help="Model identifier (default: ollama/qwen2.5-coder:32b)",
    )

    # Behaviour
    parser.add_argument(
        "--timeout", "-t",
        type=int, default=120,
        help="Seconds per attempt before declaring zombie (default: 120)",
    )
    parser.add_argument(
        "--retries", "-r",
        type=int, default=3,
        help="Max retry attempts after zombie detection (default: 3)",
    )
    parser.add_argument(
        "--mode",
        choices=["code", "agent", "ask", "architect"],
        default="code",
        help="Aider prompt mode (default: code)",
    )
    parser.add_argument(
        "--edit-format",
        choices=["diff", "whole", "udiff", "editor-diff", "editor-whole"],
        default=None,
        help="Edit format to set on the model (default: server default)",
    )

    # Connection
    parser.add_argument(
        "--base-url",
        default="http://localhost:24337",
        help="AiderDesk base URL (default: http://localhost:24337)",
    )
    parser.add_argument(
        "--ollama-url",
        default="http://localhost:11434",
        help="Ollama API URL (default: http://localhost:11434)",
    )
    parser.add_argument(
        "--username", "-u",
        default="admin",
        help="AiderDesk username (default: admin)",
    )
    parser.add_argument(
        "--password",
        default="booberry",
        help="AiderDesk password (default: booberry)",
    )

    # Project
    parser.add_argument(
        "--project-dir",
        default="/Users/ericsmith66/development/agent-forge/projects/eureka-homekit-rebuild",
        help="AiderDesk project directory",
    )
    parser.add_argument(
        "--target-file",
        default=None,
        help="Expected output file path (for on-disk detection). "
             "If not set, only Socket.IO completion is checked.",
    )

    # Toggles
    parser.add_argument(
        "--debug", "-d",
        action="store_true",
        help="Enable verbose debug output",
    )
    parser.add_argument(
        "--no-warmup",
        action="store_true",
        help="Skip Ollama model warm-up phase",
    )
    parser.add_argument(
        "--no-cleanup",
        action="store_true",
        help="Skip deleting existing tasks before starting",
    )
    parser.add_argument(
        "--no-tail-logs",
        action="store_true",
        help="Disable tailing Ollama and AiderDesk log files",
    )
    parser.add_argument(
        "--warmup-timeout",
        type=int, default=300,
        help="Timeout for Ollama warm-up request in seconds (default: 300)",
    )

    return parser.parse_args()


# ── Main ─────────────────────────────────────────────────────────────────────
# PORTABLE: The main() orchestration logic is language-agnostic.
# Most of the flow (health check → warm-up → setup → attempt loop → results)
# translates directly to Ruby. Replace Python-specific calls with Ruby equivalents
# as noted in the component sections above.

def main():
    args = parse_args()

    global DEBUG
    DEBUG = args.debug

    api_url = f"{args.base_url}/api"
    auth = HTTPBasicAuth(args.username, args.password)
    project_dir = args.project_dir
    model = args.model
    # ── Resolve prompt: --prompt-file overrides --prompt ───────────────────
    if args.prompt_file:
        prompt_file_path = args.prompt_file
        if not os.path.isabs(prompt_file_path):
            prompt_file_path = os.path.abspath(prompt_file_path)
        if not os.path.exists(prompt_file_path):
            log("FAIL", f"Prompt file not found: {prompt_file_path}")
            sys.exit(1)
        with open(prompt_file_path, "r") as pf:
            prompt = pf.read().strip()
        if not prompt:
            log("FAIL", f"Prompt file is empty: {prompt_file_path}")
            sys.exit(1)
        log("INFO", f"Loaded prompt from file: {prompt_file_path} ({len(prompt)} chars)")
    else:
        prompt = args.prompt
    timeout = args.timeout
    max_attempts = args.retries
    mode = args.mode
    target_file = args.target_file

    # Per-phase timing metrics
    phases = {}

    print("=" * 70)
    log("INFO", "AiderDesk + Ollama Prompt Runner")
    log("INFO", f"Model:        {model}")
    log("INFO", f"Timeout:      {timeout}s per attempt")
    log("INFO", f"Max attempts: {max_attempts}")
    log("INFO", f"Mode:         {mode}")
    log("INFO", f"Edit format:  {args.edit_format or '(server default)'}")
    log("INFO", f"Prompt:       {prompt[:80]}{'...' if len(prompt) > 80 else ''}")
    if target_file:
        log("INFO", f"Target file:  {target_file}")
    log("INFO", f"Debug:        {DEBUG}")
    print("=" * 70)

    # ── Phase: AiderDesk health check ────────────────────────────────────────
    t0 = time.time()
    if not health_check(api_url, auth):
        log("FAIL", f"Cannot reach AiderDesk at {args.base_url}")
        sys.exit(1)
    log("PASS", "AiderDesk is reachable")
    phases["aiderdesk_health"] = round(time.time() - t0, 2)

    # ── Phase: Ollama health check ───────────────────────────────────────────
    t0 = time.time()
    short_model = model.replace("ollama/", "")
    if not check_ollama_health(short_model, args.ollama_url):
        log("FAIL", "Ollama not available — exiting")
        sys.exit(1)
    check_ollama_running_models(args.ollama_url)
    phases["ollama_health"] = round(time.time() - t0, 2)

    # ── Phase: Ollama warm-up ────────────────────────────────────────────────
    if not args.no_warmup:
        t0 = time.time()
        warm_up_ollama(short_model, timeout=args.warmup_timeout, ollama_url=args.ollama_url)
        phases["warm_up"] = round(time.time() - t0, 2)
    else:
        log("INFO", "Skipping Ollama warm-up (--no-warmup)")

    # ── Start log tailers ────────────────────────────────────────────────────
    ollama_stop = threading.Event()
    aiderdesk_stop = threading.Event()
    if not args.no_tail_logs:
        ollama_log = os.path.expanduser("~/.ollama/logs/server.log")
        _today = datetime.now().strftime("%Y-%m-%d")
        aiderdesk_log = os.path.expanduser(
            f"~/Library/Application Support/aider-desk-dev/logs/combined-{_today}.log"
        )
        log("INFO", f"Tailing Ollama logs from: {ollama_log}")
        log("INFO", f"Tailing AiderDesk logs from: {aiderdesk_log}")
        ollama_stop = start_log_tailer(ollama_log, "OLLAMA")
        aiderdesk_stop = start_log_tailer(aiderdesk_log, "AIDESK")

    # ── Set up project ───────────────────────────────────────────────────────
    t0 = time.time()
    api_post(api_url, auth, "/project/add-open", {"projectDir": project_dir})
    api_post(api_url, auth, "/project/set-active", {"projectDir": project_dir})
    log("INFO", f"Project set active: {project_dir}")

    # Optionally set edit format at the project level
    if args.edit_format:
        log("INFO", f"Setting edit format to '{args.edit_format}' for {model}")
        api_post(api_url, auth, "/project/settings/edit-formats", {
            "projectDir": project_dir,
            "updatedFormats": {model: args.edit_format},
        })

    # Set auto-approve at project level
    api_post(api_url, auth, "/project/settings/update", {
        "projectDir": project_dir,
        "autoApprove": True,
    })

    # ── Clean up existing tasks ──────────────────────────────────────────────
    if not args.no_cleanup:
        log("INFO", "Deleting all existing tasks before starting...")
        try:
            tasks_res = api_get(api_url, auth, f"/project/tasks?projectDir={project_dir}")
            if tasks_res.status_code == 200:
                tasks_list = tasks_res.json()
                if isinstance(tasks_list, list) and len(tasks_list) > 0:
                    log("INFO", f"  Found {len(tasks_list)} existing task(s) — deleting all")
                    for t in tasks_list:
                        tid = t.get("id", "")
                        if tid:
                            try:
                                api_post(api_url, auth, "/project/tasks/delete", {
                                    "projectDir": project_dir,
                                    "id": tid,
                                })
                            except Exception as e:
                                log("WARN", f"    Failed to delete {tid}: {e}")
                    log("PASS", "All existing tasks deleted")
                else:
                    log("INFO", "  No existing tasks found — clean slate")
        except Exception as e:
            log("WARN", f"Could not delete existing tasks: {e}")
        time.sleep(2)
    phases["setup"] = round(time.time() - t0, 2)

    # ── Remove target file if it exists ──────────────────────────────────────
    if target_file and os.path.exists(target_file):
        log("INFO", f"Removing pre-existing {target_file}")
        os.remove(target_file)
        log("PASS", "File removed — clean slate")

    # ── Connect Socket.IO event monitor ──────────────────────────────────────
    monitor = EventMonitor(task_id="pending", base_url=args.base_url, project_dir=project_dir)
    if not monitor.connect(args.username, args.password):
        log("FAIL", "Could not connect Socket.IO — cannot monitor events")
        sys.exit(1)
    log("PASS", "Socket.IO event monitor connected")

    # ── Attempt loop ─────────────────────────────────────────────────────────
    task_id = None
    completed = False
    file_exists = False
    total_start = time.time()

    for attempt in range(1, max_attempts + 1):
        print()
        print("━" * 70)
        log("INFO", f"  ATTEMPT {attempt} of {max_attempts}")
        print("━" * 70)

        # Check Ollama status at start of each attempt
        check_ollama_running_models(args.ollama_url)

        # ── Create a fresh task ──────────────────────────────────────────
        t0 = time.time()
        task_name = f"Prompt #{attempt} - {datetime.now().strftime('%H:%M:%S')}"
        res = api_post(api_url, auth, "/project/tasks/new", {
            "projectDir": project_dir,
            "name": task_name,
            "activate": True,
        })
        if res.status_code != 200:
            log("FAIL", f"Could not create task: {res.status_code} {res.text[:200]}")
            continue

        task_id = res.json().get("id")
        log("PASS", f"Task created: {task_id}")
        monitor.update_task_id(task_id)

        # ── Configure model and task ─────────────────────────────────────
        api_post(api_url, auth, "/project/settings/main-model", {
            "projectDir": project_dir,
            "taskId": task_id,
            "mainModel": model,
        })
        api_post(api_url, auth, "/project/tasks", {
            "projectDir": project_dir,
            "id": task_id,
            "updates": {"autoApprove": True, "currentMode": mode},
        })
        log("INFO", f"Model={model}, autoApprove=true, mode={mode}")
        phases["task_creation"] = round(time.time() - t0, 2)

        # ── Pre-create empty target file if specified ────────────────────
        if target_file:
            if os.path.exists(target_file):
                os.remove(target_file)
            target_basename = os.path.basename(target_file)
            log("INFO", f"Pre-creating empty {target_basename} for edit-format")
            open(target_file, "w").close()
            client_add = api_post(api_url, auth, "/add-context-file", {
                "projectDir": project_dir,
                "taskId": task_id,
                "path": target_basename,
                "readOnly": False,
            })
            if client_add.status_code == 200:
                log("PASS", f"{target_basename} added to task context")
            else:
                log("WARN", f"Could not add file to context: {client_add.status_code}")

        time.sleep(3)  # let backend stabilize

        # ── Submit prompt ────────────────────────────────────────────────
        log("INFO", f"Submitting prompt ({len(prompt)} chars)...")
        prompt_result, prompt_thread = fire_prompt_async(
            api_url, auth, project_dir, task_id, prompt, mode,
        )
        log("INFO", f"Waiting up to {timeout}s for completion...")
        print("-" * 70)

        attempt_start = time.time()
        attempt_completed = False
        file_on_disk = False
        first_chunk_time = None

        while True:
            elapsed = time.time() - attempt_start

            # ── Track first chunk time ───────────────────────────────────
            if monitor.chunks_received > 0 and first_chunk_time is None:
                first_chunk_time = round(elapsed, 2)
                phases["first_chunk"] = first_chunk_time

            # ── Check for completion via Socket.IO ───────────────────────
            if monitor.completed.is_set():
                log("PASS", f"✅ response-completed received after {round(elapsed, 1)}s")
                log("INFO", f"  Total chunks received: {monitor.chunks_received}")
                phases["completion"] = round(elapsed, 2)
                attempt_completed = True
                break

            # ── Check for question via Socket.IO ─────────────────────────
            if monitor.question_pending.is_set():
                log("QUESTION", f"Task asking: {monitor.question_text}")
                log("QUESTION", "Auto-answering: 'yes'")
                try:
                    api_post(api_url, auth, "/project/answer-question", {
                        "projectDir": project_dir,
                        "taskId": task_id,
                        "answer": "yes",
                    })
                    monitor.question_pending.clear()
                except Exception as e:
                    log("WARN", f"Failed to answer question: {e}")

            # ── Check if target file has content on disk ─────────────────
            if target_file and not file_on_disk:
                if os.path.exists(target_file) and os.path.getsize(target_file) > 0:
                    log("INFO", f"📄 {os.path.basename(target_file)} has content on disk")
                    file_on_disk = True
                    file_exists = True
                    phases["file_on_disk"] = round(elapsed, 2)

            # ── Early success: file on disk + dropped from chat ──────────
            if monitor.file_dropped and file_on_disk:
                log("DETECT", "✅ File created on disk AND dropped from chat — early success")
                log("DETECT", "  Interrupting to prevent redundant second pass...")
                try:
                    api_post(api_url, auth, "/project/interrupt", {
                        "projectDir": project_dir,
                        "taskId": task_id,
                    })
                except Exception:
                    pass
                attempt_completed = True
                break

            # ── Stale chunk detection ────────────────────────────────────
            if monitor.chunks_received > 0:
                stale = time.time() - monitor.last_activity
                if stale > STALE_CHUNK_TIMEOUT:
                    log("WARN", f"No new chunks for {round(stale)}s — generation may have stalled")

            # ── Check if run-prompt thread finished ──────────────────────
            if prompt_result["done"] and not monitor.completed.is_set():
                if prompt_result["error"]:
                    log("WARN", f"run-prompt thread error: {prompt_result['error']}")
                else:
                    log("INFO", f"run-prompt returned HTTP {prompt_result['status']}")
                time.sleep(2)
                if monitor.completed.is_set():
                    attempt_completed = True
                    break
                if target_file and os.path.exists(target_file) and os.path.getsize(target_file) > 0:
                    log("INFO", "run-prompt finished + file has content — treating as success")
                    file_exists = True
                    attempt_completed = True
                    break

            # ── Timeout → classify failure ───────────────────────────────
            if elapsed > timeout:
                reason = classify_failure(monitor, prompt_result, elapsed)
                stale_duration = round(time.time() - monitor.last_activity, 1)
                print()
                log("TIMEOUT", f"⚠️  No completion within {timeout}s.")
                log("TIMEOUT", f"  Failure reason:  {reason}")
                log("TIMEOUT", f"  Chunks received: {monitor.chunks_received}")
                log("TIMEOUT", f"  Stale for:       {stale_duration}s")
                log("TIMEOUT", f"  run-prompt done={prompt_result['done']}, "
                               f"status={prompt_result['status']}, error={prompt_result['error']}")

                # Check Ollama state when failure occurs
                check_ollama_running_models(args.ollama_url)

                # Interrupt the stuck task
                log("INFO", f"Interrupting task {task_id}...")
                try:
                    int_res = api_post(api_url, auth, "/project/interrupt", {
                        "projectDir": project_dir,
                        "taskId": task_id,
                    })
                    if int_res.status_code == 200:
                        log("INFO", "Interrupt sent successfully")
                    else:
                        log("WARN", f"Interrupt returned {int_res.status_code}")
                except Exception as e:
                    log("WARN", f"Interrupt failed: {e}")
                time.sleep(2)
                break

            time.sleep(1)

        if attempt_completed or file_exists:
            completed = True
            break

        # Breather between attempts
        if attempt < max_attempts:
            log("INFO", "Waiting 5s before next attempt...")
            time.sleep(5)

    # ── Final results ────────────────────────────────────────────────────────
    total_elapsed = round(time.time() - total_start, 1)
    if target_file and not file_exists:
        file_exists = os.path.exists(target_file) and os.path.getsize(target_file) > 0

    print()
    print("=" * 70)
    log("INFO", "  FINAL RESULTS")
    print("=" * 70)
    log("INFO", f"  Total elapsed:     {total_elapsed}s")
    log("INFO", f"  Task ID:           {task_id}")
    log("INFO", f"  Completed signal:  {completed}")
    if target_file:
        log("INFO", f"  File created:      {file_exists}")
    log("INFO", f"  Chunks received:   {monitor.chunks_received}")

    # Print phase timing
    if phases:
        print()
        log("INFO", "  Phase timing (seconds):")
        for phase, duration in phases.items():
            log("INFO", f"    {phase:20s} {duration:>8.2f}s")

    print()

    # Stop log tailers and Socket.IO
    ollama_stop.set()
    aiderdesk_stop.set()
    monitor.disconnect()

    if completed or file_exists:
        log("PASS", "✅ Prompt processed successfully.")
        if target_file and file_exists:
            print()
            basename = os.path.basename(target_file)
            print(f"--- {basename} (first 30 lines) ---")
            try:
                with open(target_file) as f:
                    for i, line in enumerate(f):
                        if i >= 30:
                            break
                        print(f"  {line}", end="")
            except Exception as e:
                log("WARN", f"Could not read file: {e}")
        sys.exit(0)
    else:
        log("FAIL", f"❌ All {max_attempts} attempts failed.")
        print()
        log("INFO", "  Troubleshooting:")
        log("INFO", "    1. Check Ollama is running:  ollama ps")
        log("INFO", "    2. Check model is loaded:    curl http://localhost:11434/api/tags")
        log("INFO", "    3. Restart Ollama:           ollama stop && ollama serve")
        log("INFO", "    4. Try with --no-warmup if warm-up itself is hanging")
        log("INFO", "    5. Try --edit-format whole to avoid SEARCH/REPLACE issues")
        log("INFO", "    6. Try --mode agent for better multi-step handling")
        sys.exit(1)


if __name__ == "__main__":
    main()
