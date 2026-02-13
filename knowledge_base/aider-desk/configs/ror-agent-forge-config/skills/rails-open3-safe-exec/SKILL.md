---
name: Rails Open3 Safe Exec
description: Safe external command execution using Open3 with strict error handling.
---

## When to use
- Any external command invocation (e.g., curl to Prefab API)

## Required conventions
- Use `Open3.capture3` or `Open3.capture2e`
- Capture stdout/stderr and exit status
- Escape/quote user-controlled values

## Example
```ruby
# Preferred pattern with 3-attempt fixed-sleep retry
attempts = 0
begin
  attempts += 1
  stdout, stderr, status = Open3.capture3(*cmd, timeout: 5.seconds)
  if status.success?
    { success: true, value: stdout }
  else
    raise "Open3 failed: #{stderr}" if attempts < 3
    { success: false, error: stderr.presence || stdout }
  end
rescue StandardError => e
  if attempts < 3
    sleep 0.5
    retry
  end
  { success: false, error: e.message }
end
```
