---
name: Rails API Design
description: Consistent JSON APIs with versioning, errors, and pagination.
---

## When to use
- Building or refactoring JSON endpoints
- Introducing public or partner APIs

## Required conventions
- Use versioned namespaces (e.g., `Api::V1`)
- Return consistent error payloads and HTTP status codes
- Paginate collections with stable cursors or page params

## Examples
```ruby
render json: { data: serializer(order), meta: { request_id: request.request_id } }, status: :ok
```

## Do / Don’t
**Do**:
- Use `application/json` and explicit response schemas
- Provide error codes for client handling

**Don’t**:
- Return 200 for error states
- Change response shape without versioning
