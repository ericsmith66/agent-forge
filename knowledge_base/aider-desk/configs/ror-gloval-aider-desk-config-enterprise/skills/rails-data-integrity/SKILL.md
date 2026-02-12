---
name: Rails Data Integrity
description: Database constraints, migrations, and transactional safety.
---

## When to use
- Changing database schemas or data flows
- Introducing uniqueness or referential constraints

## Required conventions
- Prefer database constraints in addition to model validations
- Use safe migrations for large tables (add columns with defaults carefully)
- Wrap multi-write operations in transactions

## Examples
```ruby
add_index :users, :email, unique: true
```

## Do / Don’t
**Do**:
- Add foreign keys when appropriate
- Validate data before backfills

**Don’t**:
- Rely only on application validations for critical constraints
- Run long data backfills in a single transaction
