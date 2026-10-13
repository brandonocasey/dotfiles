# Local mods

Each mod here is a Claude Code plugin in the `local-mods` marketplace. Claude Code runs the copy installed in its plugin cache, not these files, and `claude plugin update` skips a mod whose version did not change.

After changing any file in a mod, before reporting the change done:

1. Run `claude plugin test .` in the mod's directory.
2. Bump `version` in the mod's `.claude-plugin/plugin.json`: patch for fixes, minor for new behavior.
3. Reinstall it in every config directory, `~/.claude` and `~/.claude-two`, at every scope listed for it in that directory's `plugins/installed_plugins.json`:

   ```sh
   CLAUDE_CONFIG_DIR=<dir> claude plugin marketplace update local-mods
   CLAUDE_CONFIG_DIR=<dir> claude plugin update <mod>@local-mods --scope <scope>
   ```

4. Check that every entry for `<mod>@local-mods` in each `installed_plugins.json` shows the new version.
5. Tell the user to restart Claude Code to load it.

These files are chezmoi targets. Sync changes to the source with the `dotfiles-sync` skill.
