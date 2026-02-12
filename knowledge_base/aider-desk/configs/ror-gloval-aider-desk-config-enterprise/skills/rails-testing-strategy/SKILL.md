---
name: Rails Testing Strategy
description: Layered testing with unit, request, and system specs.
---

## When to use
- Introducing new features or refactors
- Debugging regressions or flaky tests

## Required conventions
- Prefer unit tests for pure logic and services
- Use request specs for HTTP endpoints
- Keep system tests for critical user flows only

## Examples
```ruby
RSpec.describe Payments::CaptureCharge do
  it "captures the order" do
    result = described_class.new(order).call
    expect(result).to be_success
  end
end
```

## Do / Don’t
**Do**:
- Keep tests deterministic and isolated
- Use factories/fixtures consistently

**Don’t**:
- Depend on external services in unit tests
- Overuse system tests for simple logic
