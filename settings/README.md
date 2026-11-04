# App preferences

Bootstrap's final hook runs `scripts/bootstrap-apps.rb` after dotfiles deployment
and the bootstrap task. It restores the allowlisted preferences in `apps.json`,
then opens installed apps in the background. Apps in `/Applications` and
`~/Applications` are supported, regardless of the selected package profile.
Missing apps are skipped. Restore/launch failures are warnings; a failed restore
skips that app's launch rather than starting it with incomplete settings.

Preview without changing preferences or launching apps:

```sh
mise exec ruby -- ruby scripts/bootstrap-apps.rb --dry-run
```

## Tinycast on a fresh Mac

The dotfile group deploys `home/.config/tinycast/settings.json` to
`~/.config/tinycast/settings.json`. Merely placing the file there is insufficient:
Tinycast's settings-file feature is off by default. Before launching Tinycast,
the script sets `settingsFileEnabled = true` in `com.tinycast.app`.
On launch, Tinycast imports the existing JSON after its first app scan.

This behavior is verified against Tinycast's [settings-file documentation](https://github.com/abue-ammar/tinycast/blob/main/docs/features/settings-file.md)
and `AppCore.start` / `AppSettingsKey.settingsFileEnabled`. It relies on that
preference key continuing to exist; recheck it if Tinycast changes its format.
It does not bypass onboarding or capability/permission prompts.

Tinycast follows the symlink and writes settings changes back to the repo file.
This is intentional: review those changes with `git diff` before committing.
If Tinycast was already running with the feature disabled, quit and reopen it
once after bootstrap. Bootstrap does not forcibly quit any app.

## What is managed

- **AeroSpace:** the existing `home/.config/aerospace/aerospace.toml` remains the
  source of truth. Bootstrap does not capture live window/workspace state.
- **Tinycast:** your JSON file, plus the opt-in preference above. Private content
  and credentials are not captured separately.
- **macshot:** tools/actions, filename template, OCR shortcut/action, copy sound,
  menu-bar icon, translation provider, automatic-update and login preferences.
  Sandboxed preferences use targeted `plutil` edits in the container (macOS
  `defaults` can silently ignore writes to these paths). Other apps use `defaults`. No
  screenshots, save-directory bookmarks, permission flags or transient UI state.
- **Tailscale:** Dock icon, update/telemetry channel and start-on-login preferences.
  No accounts, keys, profiles, VPN state or connection settings.
- **1Password:** launch only. Its ordinary preference domains do not expose the
  settings needed here; internal storage and vault data are deliberately untouched.
  Configure its settings in the app after signing in.

Login preference flags do not copy macOS service registration or approval.
Approve login items, VPN setup, Accessibility and Screen Recording when prompted.
Launching after bootstrap does not imply configuring every app to launch at login.

## Editing and backups

`apps.json` is an explicit, reviewed snapshot, not a live export. To change it,
inspect and copy only the intended non-secret keys. Bootstrap never rewrites it.
Values retain their types, including integer arrays; unmanaged keys remain intact.

Before applying changes, bootstrap saves the previous **managed values only** in
`~/.local/state/dotfiles/app-preferences/<timestamp>/<domain>.json` (mode 0600).
Each entry is a typed XML plist value; `null` means the key was absent.
For a normal domain, restore an entry with `defaults write DOMAIN KEY XML_VALUE`;
for an absent key, use `defaults delete DOMAIN KEY`. For an absolute sandbox domain,
use `plutil -replace KEY -xml XML_VALUE DOMAIN.plist`, or `plutil -remove KEY
DOMAIN.plist` for a previously absent key. The backup includes the exact domain.
Quit the affected app before manual rollback and reopen afterwards.

Apps can cache or overwrite preferences while running. For predictable restoration
on an existing Mac, quit the affected apps before running bootstrap. A fresh install
restores settings before the apps' first launch. No live preferences were changed
while developing this setup; tests use temporary domains only.
