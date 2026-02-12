---
name: Rails Background Jobs
description: Reliable, idempotent background processing with ActiveJob/Sidekiq.
---

## When to use
- Work that is slow, retryable, or external-API dependent
- Fan-out workflows and async notifications

## Required conventions
- Jobs must be idempotent and safe to retry
- Use explicit timeouts and error handling
- Keep job payloads small (IDs, not full objects)

## Examples
```ruby
class Billing::CaptureJob < ApplicationJob
  queue_as :billing

  def perform(order_id)
    Billing::CaptureCharge.new(order_id).call
  end
end
```

## Do / Don’t
**Do**:
- Use retry/backoff defaults for transient errors
- Record job failure context for operators

**Don’t**:
- Enqueue jobs with large serialized objects
- Make jobs non-idempotent
