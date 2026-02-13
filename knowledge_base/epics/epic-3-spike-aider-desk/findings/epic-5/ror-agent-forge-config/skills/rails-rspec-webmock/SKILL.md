---
name: Rails RSpec + WebMock
description: Testing patterns for HTTP interactions and service boundaries.
---

## When to use
- External HTTP calls (Prefab API)
- Service objects with retry logic

## Required conventions
- Use WebMock to stub external HTTP calls
- Cover success, failure, and retry exhaustion
- Assert structured response payloads

## Do / Don’t
**Do**:
- Use shared contexts for common stubs
- Validate stderr handling from Open3

**Don’t**:
- Skip tests for public methods
