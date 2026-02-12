---
name: Rails Service Patterns
description: Service objects, orchestration, and transaction boundaries for Rails.
---

## When to use
- Adding non-trivial business logic
- Coordinating multiple models or side effects

## Required conventions
- Service classes under `app/services`
- Single public `call` method
- Inputs validated at initialization

## Examples
```ruby
class Payments::CaptureCharge
  def initialize(order)
    @order = order
  end

  def call
    ActiveRecord::Base.transaction do
      # ...
    end
  end
end
```

## Do / Don’t
**Do**:
- Keep services small and focused
- Return structured results (success/failure)

**Don’t**:
- Hide side effects in model callbacks
- Mix HTTP concerns into services
