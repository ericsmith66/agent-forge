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
stdout, stderr, status = Open3.capture3(*cmd)
if status.success?
  { success: true, value: stdout }
else
  { success: false, error: stderr.presence || stdout }
end
```
