---
name: Rails Turbo Hotwire
description: Turbo Frames and Streams for server-driven UI updates.
---

## When to use
- Replacing custom JS with server-driven interactivity
- Adding partial page updates for forms and lists
- Improving perceived speed without a SPA

## Required conventions
- Prefer `turbo_frame_tag` for scoped updates
- Use `turbo_stream` responses for create/update/destroy flows
- Keep rendering server-side; avoid duplicating logic in JS

## Examples
```erb
<%= turbo_frame_tag "users" do %>
  <%= render @users %>
<% end %>
```

```ruby
respond_to do |format|
  format.turbo_stream
  format.html { redirect_to users_path }
end
```

## Do / Don’t
**Do**:
- Use Turbo for incremental updates
- Keep templates small and composable

**Don’t**:
- Introduce heavy JS frameworks for simple UI flows
- Render inconsistent partials across responses
