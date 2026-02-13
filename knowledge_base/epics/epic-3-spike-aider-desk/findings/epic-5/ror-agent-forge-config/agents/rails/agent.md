# Rails Agent (Epic 5)

Primary agent profile for Epic 5 execution. This profile delegates to subagents for specialized work:

- **debug** → reproduction-first fixes and failure analysis
- **refactor** → behavior-preserving improvements and service-layer work
- **ui** → ViewComponent + Stimulus + Tailwind/DaisyUI implementation
- **greenfield** → new files or net-new features

Use the **strict directive** rule for all Epic 5 PRD work.
