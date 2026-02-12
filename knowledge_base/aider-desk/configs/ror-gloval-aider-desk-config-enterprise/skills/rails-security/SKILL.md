---
name: Rails Security
description: Authentication, authorization, secrets handling, and secure defaults.
---

## When to use
- Adding new authenticated routes or roles
- Handling PII, secrets, or external integrations

## Required conventions
- Use strong parameters and explicit attribute whitelists
- Enforce authorization in controllers/services
- Filter sensitive params from logs

## Examples
```ruby
params.require(:user).permit(:email, :name)
```

## Do / Don’t
**Do**:
- Store secrets in environment/config, not code
- Validate ownership/permissions for data access

**Don’t**:
- Log tokens, passwords, or PII
- Use raw SQL with interpolated user input
