---
name: Rails Observability & Metrics
description: Structured logs, metrics, and tracing for production visibility.
---

## When to use
- Introducing new critical paths or background jobs
- Debugging production issues or performance regressions

## Required conventions
- Emit structured logs with stable event keys
- Include correlation IDs (`request_id`, job IDs)
- Instrument key flows with `ActiveSupport::Notifications` when available

## Examples
```ruby
ActiveSupport::Notifications.instrument("payments.capture", order_id: order.id) do
  Payments::CaptureCharge.new(order).call
end
```

## Do / Don’t
**Do**:
- Track success/failure counts for critical operations
- Add latency measurements for external calls

**Don’t**:
- Log PII or secrets
- Emit high-cardinality labels without need
