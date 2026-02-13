---
name: Rails Control Events Audit
description: Audit logging for control actions, request_id, and source fields.
---

## When to use
- Any write action to HomeKit/Prefab
- Scene execution or control endpoints

## Required conventions
- Generate `request_id` with `SecureRandom.uuid` per attempt
- Store `source`, `latency_ms`, `success`, and error details
- Log `stderr` on failures when using Open3

## Example fields
- `request_id`, `action_type`, `accessory_id`, `characteristic_name`, `old_value`, `new_value`, `success`, `error_message`, `latency_ms`, `source`
