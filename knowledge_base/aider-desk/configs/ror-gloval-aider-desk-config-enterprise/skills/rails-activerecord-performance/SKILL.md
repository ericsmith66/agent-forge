---
name: Rails ActiveRecord Performance
description: Query shaping, N+1 prevention, and indexing practices for Rails.
---

## When to use
- Hot paths with slow queries or N+1 issues
- Large datasets or heavy list endpoints

## Required conventions
- Use `includes`/`preload` to prevent N+1 queries
- Select only needed columns in read-heavy endpoints
- Add indexes for foreign keys and high-cardinality filters

## Examples
```ruby
orders = Order.includes(:line_items)
  .where(status: "paid")
  .select(:id, :number, :total_cents)
```

## Do / Don’t
**Do**:
- Use `find_each` for large batch processing
- Add query objects for complex reporting logic

**Don’t**:
- Load full associations when only IDs are needed
- Ignore missing or unused indexes on large tables
