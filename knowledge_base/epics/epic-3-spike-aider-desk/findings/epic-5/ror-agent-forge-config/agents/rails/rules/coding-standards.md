# Coding Standards (Rails)

## General
- Keep methods small and single-purpose.
- Prefer explicit, readable code over clever abstractions.
- Avoid monkey-patching and global state.

## Service Objects
- Use `call` as the only public method.
- Validate inputs in initializer or a `validate!` method.
- Return structured results (e.g., `{ success:, value:, error: }`).

## Error Handling
- Log with severity appropriate to the error class.
- Include contextual metadata in logs (IDs, request_id).
- Never swallow errors silently.

## UI/Stimulus
- Use data attributes for stimulus targets/actions.
- Keep controllers focused on one component.
- Prefer CSS utility classes and ViewComponent composition.
