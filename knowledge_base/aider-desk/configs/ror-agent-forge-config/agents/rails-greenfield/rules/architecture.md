# Architecture Guidelines for agent-forge

1. **Self-Building Meta-Framework**: Remember that agent-forge is a framework for building AI agents. Core agent logic lives in `lib/agents/`.
2. **3-Pane UI Layout**: The dashboard uses a 3-pane layout. Updates to these panes should be handled via Turbo Frames.
3. **Sub-Projects**: Managed sub-projects live in `projects/`. Each is an independent git repository. NEVER track `projects/` files in the root repo (except for `.gitignore`).
4. **Knowledge Base**: The `knowledge_base/` directory is the "brain" of the project. Always reference PRDs, Epics, and instructions there before major changes.
5. **Database**: PostgreSQL is used for development and production. Use migrations for all schema changes.
6. **Solid Stack**: Follow the baseline in `knowledge_base/epics/epic-1-bootstrap/BASELINE-GEMFILE.md`. Use Rails 8.1+ patterns with Solid Queue and Solid Cache.
7. **Background Jobs**: Use Solid Queue for long-running agent tasks.
