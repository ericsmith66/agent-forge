# Architecture (Rails)

## Boundaries
- Controllers coordinate and authorize, but do not hold business logic.
- Business logic lives in services under `app/services` with a single public `call`.
- Data persistence stays in models; keep callbacks minimal and explicit.

## Naming & Layout
- Use namespaces for domain grouping (e.g., `Controls::`, `Scenes::`).
- Prefer explicit class/module names over metaprogramming.
- Use ViewComponent for UI composition and Stimulus controllers for interactivity.

## Testing Strategy
- Unit tests for service objects and models.
- Integration tests for controllers and API boundaries.
- System tests for UI flows and optimistic updates.
