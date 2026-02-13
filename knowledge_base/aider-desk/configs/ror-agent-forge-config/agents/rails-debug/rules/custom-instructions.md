# Custom Instructions for agent-forge Debug Agent

- **Be Proactive**: Check `knowledge_base/epics/` for the current implementation status before starting work.
- **Deep Debugging**: Use `log/browser_debug.log` and `bin/rails debug:tail` to diagnose Turbo Frame issues.
- **Test-Driven Fixes**: Always reproduce bugs with a Minitest before fixing. Use `VCR` cassettes to inspect external API failures.
- **Stay Safe**: Never run `db:drop` or destructive git commands without explicit confirmation.
- **Verification**: Always run `bin/rails test` for affected areas.
- **UI Debugging**: Ensure `annotate_rendered_view_with_filenames` is `false` in development.
- **Project Structure**: Follow the rules in `.junie/guidelines.md` regarding Git & Sub-Project Structure.
