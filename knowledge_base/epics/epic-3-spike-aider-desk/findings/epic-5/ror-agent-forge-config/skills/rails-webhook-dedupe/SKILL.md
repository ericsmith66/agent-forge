---
name: Rails Webhook Deduplication
description: Prevent echo loops by deduping inbound webhook events against recent outbound controls.
---

## When to use
- Processing incoming webhook events

## Required conventions
- Query recent control events for same accessory + characteristic within 2–5 seconds
- Skip event creation if a matching outbound control exists

## Example logic
- `ControlEvent.recent_for(accessory_id, characteristic).exists?` → skip
