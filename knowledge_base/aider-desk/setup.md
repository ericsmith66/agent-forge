# AiderDesk Local Setup & Verification

**PRD:** PRD-1-01  
**Date:** 2026-02-08  
**Status:** Verified

---

## Prerequisites

- macOS with Homebrew
- [AiderDesk](https://aiderdesk.com) desktop app installed
- [Ollama](https://ollama.ai) installed and running
- Rails encrypted credentials configured with AiderDesk auth (see below)

---

## 1. Install & Start Ollama

```bash
# Install (if not already)
brew install ollama

# Start the Ollama service
ollama serve
```

### Pull Required Models

```bash
# Primary model
ollama pull qwen2.5-coder:32b-instruct

# Fallback model
ollama pull llama3.1:405b
```

> **Note:** `llama3.1:405b` requires significant RAM/VRAM. If unavailable locally, use `llama3.1:70b` as an alternative fallback.

### Verify Models

```bash
ollama list
```

Expected output should include `qwen2.5-coder:32b-instruct` (or `qwen2.5-coder:32b`).

---

## 2. Start AiderDesk

1. Launch the AiderDesk desktop application.
2. Verify it is listening on the default port:

```bash
curl -s http://localhost:24337/api/settings | head -c 200
```

- **200 OK** with JSON → AiderDesk is running (no auth required or auth disabled).
- **401 Unauthorized** → AiderDesk is running but requires Basic Auth (expected).
- **Connection refused** → AiderDesk is not running. Start the desktop app.

---

## 3. Authentication

AiderDesk uses HTTP Basic Auth. Credentials are stored in Rails encrypted credentials and must **never** be hardcoded.

### Accessing Credentials

```ruby
# In Rails console or code:
creds = Rails.application.credentials.dig(:aider_desk)
# creds[:user] and creds[:password]
```

### Testing Auth via curl

```bash
# Replace with actual credentials from Rails.application.credentials.dig(:aider_desk)
curl -u <AIDER_USER>:<AIDER_PASS> http://localhost:24337/api/settings
```

Expected: **200 OK** with JSON response containing AiderDesk settings.

---

## 4. Health Check

```bash
curl -s -u <AIDER_USER>:<AIDER_PASS> http://localhost:24337/api/settings | python3 -m json.tool | head -20
```

Expected: Valid JSON with AiderDesk configuration.

---

## 5. Send a Test Prompt

```bash
curl -u <AIDER_USER>:<AIDER_PASS> -X POST http://localhost:24337/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"projectDir": "/path/to/projects/aider-desk-test"}'
```

- Verify the task appears in the AiderDesk GUI.
- Confirm no errors in AiderDesk logs.

---

## 6. Ollama Provider Configuration

In AiderDesk settings, configure the Ollama provider:

1. Open AiderDesk → Settings → Providers
2. Add/verify Ollama provider pointing to `http://localhost:11434`
3. Set primary model: `qwen2.5-coder:32b-instruct`
4. Set fallback model: `llama3.1:405b` (or `llama3.1:70b`)

---

## Troubleshooting

### Connection Refused on Port 24337

AiderDesk desktop app is not running. Launch it from Applications.

### 401 Unauthorized

Credentials are incorrect. Verify:
```ruby
Rails.application.credentials.dig(:aider_desk)
```
Ensure the user/password match what's configured in AiderDesk settings.

### Ollama Model Not Found

```bash
# List available models
ollama list

# Pull missing model
ollama pull qwen2.5-coder:32b-instruct
```

### Port Conflict

If port 24337 is in use by another process:
```bash
lsof -i :24337
```
Change the port in AiderDesk settings if needed.

### Ollama Not Responding

```bash
# Check if Ollama is running
curl http://localhost:11434/api/tags
```

If not running: `ollama serve`

---

## Related Resources

- AiderDesk API docs: `knowledge_base/aider-desk/docs/`
- AiderDesk REST endpoints: `knowledge_base/aider-desk/docs/rest-endpoints.md`
- AiderDesk API guide: `knowledge_base/aider-desk/docs/aider_desk_api_guide.md`
- Epic overview: `knowledge_base/epics/epic-1-bootstrap/0000-overview-epic-001-aider-bootstrap.md`
