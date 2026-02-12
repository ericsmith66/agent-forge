---
name: Rails RSpec + WebMock
description: Isolate external HTTP calls in tests using WebMock and RSpec patterns.
---

## When to use
- Testing services or clients that call external APIs
- Preventing real HTTP calls in specs

## Required conventions
- Use `WebMock.disable_net_connect!` where test suite expects isolation
- Stub external requests with explicit URLs and payloads
- Keep shared stubs in `spec/support/webmock.rb` if the project uses it

## Examples
```ruby
stub_request(:post, "https://api.example.com/v1/charges")
  .with(body: hash_including("amount" => 1000))
  .to_return(status: 200, body: { id: "ch_123" }.to_json)
```

## Do / Don’t
**Do**:
- Assert on request shape (method, path, headers, body)
- Use VCR only if the project already relies on it

**Don’t**:
- Allow unstubbed network calls in unit specs
- Over-stub responses without verifying critical fields
