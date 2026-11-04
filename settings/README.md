# App preferences

Bootstrap's final hook restores allowlisted preferences from `apps.json` after
dotfiles deployment and the bootstrap task. **It never launches or quits apps.**
Installed apps in `/Applications` and `~/Applications` are supported regardless
of the selected package profile. Missing apps are skipped; restore errors are
reported as warnings and remaining apps are still processed.

## Tasks

```sh
mise run apps:capture:preview  # Preview local macshot/Tailscale changes to save
mise run apps:capture          # Save those changes to settings/apps.json
mise run apps:preview          # Preview applying the repo snapshot
mise run apps:apply            # Apply the snapshot, without opening apps
```

To save settings changed in macshot or Tailscale:

1. Quit the app so its latest preferences are flushed to disk.
2. Run `mise run apps:capture:preview`, then `mise run apps:capture`.
3. Review `git diff -- settings/apps.json`, commit and push.

Capture reads **only keys already listed for macshot and Tailscale** in
`apps.json`; it never exports new keys, credentials, account profiles or app data.
Unset keys retain the saved value with a warning: app-specific default values
cannot safely be inferred. Edit the snapshot explicitly if you want a different
value for such a key. Unsupported values or read failures abort capture without
partially saving the snapshot. Missing apps leave their snapshots unchanged.
Capture does not read Tinycast's opt-in flag back into the snapshot.

To apply saved settings on an existing Mac, quit the affected apps before
`mise run apps:apply`, then reopen them manually. Apps can cache or overwrite
preferences changed while running. Bootstrap also applies this snapshot, so
capture local changes **before** bootstrapping if you want to keep them.

## Tinycast and AeroSpace

- **Tinycast:** change preferences in the app. Its settings-file sync writes
  changes through the symlink to `home/.config/tinycast/settings.json`.
- **AeroSpace:** edit `home/.config/aerospace/aerospace.toml` directly. Live window
  positions and workspace state are not captured.

These files are deployed by the existing dotfile group. Review their Git diffs,
commit and push separately from the snapshot workflow.

### Tinycast on a fresh Mac

The dotfile group deploys `home/.config/tinycast/settings.json` to
`~/.config/tinycast/settings.json`. The script also sets `settingsFileEnabled =
true` in `com.tinycast.app`; merely placing the file there is insufficient because
the settings-file feature is off by default. **When you first open Tinycast
manually**, it imports the existing JSON after its first app scan.

This behavior is verified against Tinycast's [settings-file documentation](https://github.com/abue-ammar/tinycast/blob/main/docs/features/settings-file.md)
and `AppCore.start` / `AppSettingsKey.settingsFileEnabled`. Recheck that key if
Tinycast changes its format. It does not bypass onboarding or capability prompts.
If Tinycast was already running with sync disabled, quit and reopen it after apply.

## Managed snapshot

- **macshot:** tools/actions, filename template, OCR shortcut/action, copy sound,
  menu-bar icon, translation provider, automatic-update and login preferences.
  Sandboxed preferences use targeted `plutil` edits in the container (`defaults`
  can silently ignore writes to these paths). No screenshots, save-directory
  bookmarks, permission flags or transient UI state.
- **Tailscale:** Dock icon, update/telemetry channel and start-on-login preferences.
  No accounts, keys, profiles, VPN state or connection settings.
- **Tinycast:** only the settings-file opt-in flag; its settings use the JSON above.
- **1Password:** no preferences are managed. Configure it manually after sign-in;
  its internal storage and vault data are deliberately untouched.

Existing launch-at-login preferences remain managed; they are separate from
launching apps after bootstrap, which has been removed. Preference flags cannot
copy macOS service registration or approval. Approve login items, VPN setup,
Accessibility and Screen Recording when prompted.

## Backups

Before applying changes, the script saves previous **managed values only** in
`~/.local/state/dotfiles/app-preferences/<timestamp>/<domain>.json` (mode 0600).
Entries are typed XML plist values; `null` means the key was absent.

For a normal domain, restore with `defaults write DOMAIN KEY XML_VALUE`, or
`defaults delete DOMAIN KEY` for a previously absent key. For an absolute sandbox
domain, use `plutil -replace KEY -xml XML_VALUE DOMAIN.plist`, or
`plutil -remove KEY DOMAIN.plist`. The backup contains the exact domain.
Quit the app before manual rollback and reopen afterwards.
