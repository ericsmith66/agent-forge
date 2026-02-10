#### PRD-2-08: Enhanced UI Debugging & Observability

**PRD ID:** PRD-002.8  
**Version:** 1.0  
**Owner:** Junie (AI Architect)  
**Date:** 2026-02-10  
**Status:** Implemented  
**Dependencies:** PRD-002.7

---

### 1. Overview

Epic 2 implementation revealed that standard JS error capturing (implemented in PRD-2-07) is insufficient for troubleshooting "Rough UI" issues. Specifically, silent CSS failures (404s), structural Turbo Frame mismatches, and layout-breaking view annotations do not trigger JS exceptions. This PRD defines an enhanced debugging suite to provide AI agents with high-fidelity visibility into the browser's state.

### 2. Requirements

#### 2.1 Resource Error Monitoring
- **Goal:** Capture failed asset loads (CSS, JS, Images) which are currently silent to the `console.error` hook.
- **Implementation:** 
  - Update `debug_controller.js` to use `window.addEventListener('error', ..., true)` to capture resource load failures.
  - Filter for `link`, `script`, and `img` tags.
  - Log the failed URL and the tag type to the server-side `browser_debug.log`.

#### 2.2 Turbo Lifecycle Logging
- **Goal:** Visibility into Turbo Frame failures and navigation issues.
- **Implementation:**
  - Intercept Turbo events:
    - `turbo:frame-missing`: Log when a requested frame ID is not found in the response. This is the #1 cause of "empty" or "broken" panes.
    - `turbo:error`: Log any HTTP errors during Turbo requests.
    - `turbo:frame-load`: Log successful frame updates (low priority, maybe debug level).
  - Log the frame ID, the URL, and the status code.

#### 2.3 DOM Health Checks & Snapshots
- **Goal:** Detect "HTML leaks" (like view annotations) and structural anomalies.
- **Implementation:**
  - **Annotation Detector:** Periodically or on frame load, check for the presence of specific HTML comments (e.g., `<!-- BEGIN`) and log a warning if found, as these break Turbo.
  - **Frame ID Validation:** Cross-reference the requested Turbo Frame ID with the actual DOM to ensure no mismatches.
  - **On-Demand Snapshot:** Add a mechanism (e.g., a specific slash command `/debug-ui`) that triggers a log entry containing a sanitized snippet of the `document.body.innerHTML` or the specific content of a failing Turbo Frame.

#### 2.4 Server-Side Log Enrichment
- **Implementation:**
  - Update `DebugLogsController` to handle larger payloads if snapshots are sent.
  - Ensure log entries include the User-Agent and viewport dimensions (helpful for layout issues).

---

### 3. Implementation Details

- **Files to Modify:**
  - `app/javascript/controllers/debug_controller.js`
  - `app/controllers/debug_logs_controller.rb`
  - `app/views/layouts/application.html.erb` (ensure debug controller is always present in dev)
- **New Files:**
  - `app/javascript/utils/debug_helpers.js` (optional, for DOM sanitization)

---

### 4. Success Criteria

1. Failed CSS CDN links (like the DaisyUI 404) appear in `log/browser_debug.log` within 2 seconds.
2. If a Turbo Frame ID is misspelled or missing in the response, an `[ERROR] [TURBO] Frame missing: ...` entry appears in the logs.
3. AI agents can use the logs to identify why a pane is "blank" without needing the user to open DevTools.
