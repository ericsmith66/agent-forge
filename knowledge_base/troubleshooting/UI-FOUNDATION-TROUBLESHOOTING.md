# UI Foundation Troubleshooting & Resolutions (Epic 2)

**Date:** 2026-02-09  
**Author:** Junie (AI Architect)  
**Subject:** Troubleshooting the "Rough" UI, HTML Leaks, and Asset Pipeline Stability

---

## 1. The Core Issue: "HTML Leaking" into Turbo Frames
### Symptom
The user reported seeing `<div></div>` or `<!-- BEGIN/END -->` comments inside the Artifact Viewer (the 3rd pane). This made the pane appear non-functional or visually broken.

### Root Cause
Rails has a development feature called `annotate_rendered_view_with_filenames`. When enabled, it wraps every partial and component in HTML comments (e.g., `<!-- BEGIN app/views/... -->`).
Turbo Frames are extremely sensitive to the HTML structure returned by the server. If a response starts or ends with a comment or stray tag outside the `<turbo-frame>` tag matching the request ID, Turbo may fail to extract the content correctly or, worse, render the comments/tags as literal text inside the UI.

### Resolution
Disabled view annotations in all environments:
- **File:** `config/environments/development.rb` and `config/environments/test.rb`
- **Change:** `config.action_view.annotate_rendered_view_with_filenames = false`

---

## 2. Asset Pipeline & CSS 404s
### Symptom
The UI appeared "rough" or unstyled, with panels not visually separated. Logs showed `404 Not Found` for `full.min.css` (DaisyUI).

### Root Cause
The project uses `tailwindcss-rails` (Tailwind 4), but the local environment lacked a `node_modules` setup for the DaisyUI plugin. The attempt to bridge this with a CDN-based setup initially used an outdated or incorrect URL.

### Resolution
- Standardized the application layout to use a working DaisyUI CDN URL alongside the local Tailwind build.
- **Action:** `bin/rails assets:clobber && bin/rails tailwindcss:build` was run to ensure no stale cached CSS interfered with the new high-fidelity tokens.
- **Verification:** Hard refresh (`Cmd+Shift+R`) is required after clobbering to ensure the browser fetches the new asset manifest.

---

## 3. Interaction Stability: Persistent Menus
### Symptom
The "Project Switcher" dropdown remained open after selecting a project, obscuring the dashboard.

### Root Cause
DaisyUI dropdowns use CSS focus/blur or specific checkbox hacks. In a Turbo-driven SPA, clicking a link inside the dropdown triggers a frame/body swap, but since the page doesn't "reload," the browser doesn't necessarily lose focus on the dropdown trigger, keeping it open.

### Resolution
Implemented a robust `ProjectSwitcherController` (Stimulus):
- **Action:** On project selection, the controller explicitly calls `this.element.removeAttribute('open')` (for `<details>` based dropdowns) and `document.activeElement.blur()`.
- **Result:** The menu closes instantly, providing a seamless transition.

---

## 4. Debugging Strategy: The "Browser Debug Loop"
### Requirement
Per PRD-2-07, a minimal debug capability was needed to catch JS errors that Junie couldn't "see" in the terminal.

### Implementation
1. **Stimulus Interceptor:** `debug_controller.js` attaches to the `window` and intercepts `console.error` and `console.warn`.
2. **Server-side Logger:** It sends these errors via `fetch` to a hidden route `/debug/log` (only in development).
3. **Rake Task:** A new task `rake debug:tail` was created to allow the user (and Junie) to see browser-side errors directly in the server console.

### Why it didn't help with the "Rough UI" (and how to fix it)
The Debug Loop was active, but it didn't surface the most critical Epic 2 issues for several reasons:
- **Structural Mismatches:** The "HTML leak" was a valid (but unintended) HTML sequence. Turbo Frames didn't throw a JS error; they simply rendered the stray comments or failed to update the DOM quietly.
- **Silent CSS Failures:** Browser-side `404` errors for CSS files (like the DaisyUI CDN failure) are logged to the browser console by the engine, but they are **not** caught by `console.error` or `window.onerror`.
- **Timing:** In the heat of troubleshooting, I relied on manual inspection of the `preview.html` vs the Rails output instead of checking the `browser_debug.log`.

### Proposed Enhancements to the Debug Loop
To make this tool more effective for "Rough UI" troubleshooting, we should add:
1. **Resource Error Monitoring:** Add a `window.addEventListener('error', ..., true)` specifically to catch failed `<link>` and `<script>` tag loads. This would have instantly flagged the DaisyUI 404 in the server logs.
2. **Turbo Lifecycle Logging:** Intercept `turbo:frame-missing` and `turbo:error` events. These would have explicitly logged when the Artifact Viewer failed to find a matching frame ID.
3. **Screenshot/DOM Snapshot:** For critical errors, send a snippet of the current `document.body.innerHTML` to the server log to pinpoint "leaked" tags.

---

## 5. Lessons for Future Self
1. **Check the Debug Log Early:** Even if no "crash" is apparent, the `browser_debug.log` (via `rake debug:tail`) should be the first place to look when UI looks "off."
2. **Trust the Preview:** When the user says "it doesn't look like the vision," check the basic HTML structure first. Nested Turbo Frames are a common source of "blank" panes.
3. **Clobber Often:** In development, Sprockets/Propshaft can get stuck on old manifest versions after significant layout changes.
4. **Canonical IDs:** Always ensure the `turbo_frame_tag` ID in the placeholder matches exactly what the controller returns. A single typo (e.g., `artifact-viewer` vs `artifact_viewer`) results in a silent failure where the UI simply doesn't update.
5. **Visibility:** If icons or borders aren't appearing, check the Network tab for 404s before diving into the Ruby code. 90% of "rough UI" issues in Epic 2 were CSS load failures.

---
*End of Document*
