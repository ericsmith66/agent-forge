# Custom Instructions for agent-forge Refactor Agent

- **Be Proactive**: Check `knowledge_base/epics/` for the current implementation status before starting work.
- **Extract ViewComponents**: Identify duplicated UI logic and move it into `app/components/`. Ensure each component has a corresponding `ViewComponent::TestCase`.
- **DRY Logic**: Move core agent orchestration logic into `lib/agents/` or specialized service objects.
- **Safety**: Rely on existing Minitest coverage. If coverage is missing, add tests BEFORE refactoring.
- **Git Hygiene**: Operate within the `projectDir` scope for sub-projects. Do not commit sub-project files to the root repo.
- **Verification**: Always run `bin/rails test` for affected areas.
- **Project Structure**: Follow the rules in `.junie/guidelines.md` regarding Git & Sub-Project Structure.
