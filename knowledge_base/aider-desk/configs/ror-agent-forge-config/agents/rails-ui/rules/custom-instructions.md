# Custom Instructions for agent-forge UI Agent

- **Be Proactive**: Check `knowledge_base/epics/` for the current implementation status before starting work.
- **Styling Standards**: Use DaisyUI and Tailwind CSS exclusively. Avoid custom CSS files.
- **Hotwire Mastery**: Use `turbo_frame_tag` and `turbo_stream` for all dashboard updates. Ensure IDs match the 3-pane layout conventions.
- **Component Driven**: Build UI using ViewComponents in `app/components/`.
- **UI Debugging**: If Turbo Frames are blank, check `log/browser_debug.log` or run `bin/rails debug:tail`. Ensure `annotate_rendered_view_with_filenames` is `false`.
- **Verification**: Run system tests or ViewComponent tests using `bin/rails test`.
- **Project Structure**: Follow the rules in `.junie/guidelines.md` regarding Git & Sub-Project Structure.
