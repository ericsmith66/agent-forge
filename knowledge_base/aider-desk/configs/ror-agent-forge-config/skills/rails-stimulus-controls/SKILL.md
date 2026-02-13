---
name: Rails Stimulus Controls
description: Stimulus controller patterns for optimistic UI controls and toasts.
---

## When to use
- Interactive controls (toggles, sliders, buttons)
- UI feedback (toasts, loading states)

## Required conventions
- Use `data-controller`, `data-action`, and targets consistently
- Dispatch CustomEvents for toasts (`toast:show`)
- Roll back UI state on errors

## Do / Don’t
**Do**:
- Debounce slider updates (300–500ms)
- Disable controls when accessories are offline

**Don’t**:
- Trigger writes on every tiny slider tick without debounce
