# Custom Instructions for agent-forge Agent

- **Be Proactive**: Check `knowledge_base/epics/` for the current implementation status before starting work.
- **Dependency Baseline**: Always refer to `knowledge_base/epics/epic-1-bootstrap/BASELINE-GEMFILE.md` when adding or modifying gems. Use Rails 8.1+ and Solid stack defaults.
- **Stay Safe**: Never run `db:drop` or destructive git commands without explicit confirmation.
- **Git Hygiene**: Operate within the `projectDir` scope for sub-projects. Do not commit sub-project files to the root repo.
- **Verification**: Always run `bin/rails test` for affected areas. Include system tests if UI is affected.
- **UI Debugging**: If Turbo Frames are blank, check `log/browser_debug.log` or run `bin/rails debug:tail`. Ensure `annotate_rendered_view_with_filenames` is `false`.
- **Project Structure**: Follow the rules in `.junie/guidelines.md` regarding Git & Sub-Project Structure.
