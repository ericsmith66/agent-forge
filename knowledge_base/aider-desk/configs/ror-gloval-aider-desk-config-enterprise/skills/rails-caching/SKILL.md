---
name: Rails Caching
description: Cache keys, invalidation, and safe caching for performance.
---

## When to use
- Read-heavy endpoints with stable responses
- Expensive computations or repeated renders

## Required conventions
- Use versioned cache keys and explicit expirations
- Avoid caching PII or authorization-specific data without scoping
- Use `Rails.cache.fetch` with deterministic keys

## Examples
```ruby
Rails.cache.fetch(["orders", order.id, order.updated_at.to_i], expires_in: 10.minutes) do
  Orders::Presenter.new(order).as_json
end
```

## Do / Don’t
**Do**:
- Invalidate caches on writes
- Cache at the lowest stable layer (query/presenter)

**Don’t**:
- Cache data without a clear invalidation plan
- Cache user-specific data under shared keys
