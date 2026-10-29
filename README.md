# dotfiles

macOS setup managed entirely by [mise](https://mise.jdx.dev/bootstrap.html).
Everything lives in [`mise.toml`](mise.toml):

| What | Where in `mise.toml` |
| --- | --- |
| Dotfiles: git-tracked files in `home/` linked into `$HOME` | `[dotfiles]` |
| Homebrew formulae and casks (no Homebrew install needed) | `[bootstrap.packages]` |
| Dock, Finder, keyboard, trackpad, screenshots | `[bootstrap.macos.*]` |
| Login shell (fish) | `[bootstrap.user]` |
| Dev tools (node, bun, pi, …) | `home/.config/mise/config.toml` → `[tools]` |
| Vite+, Rex skill, Caps Lock → Esc | `[tasks.bootstrap]` and `setup:*` tasks |

## Profiles

Profile-specific packages use `env = "<profile>"`. Each machine picks its
profile in `.miserc.local.toml` (not committed):

```toml
env = ["personal"] # or ["work"]
```

## New machine

Paste this into Terminal on a fresh Mac, enter your password once, and walk away.
Set `PROFILE` to `personal` or `work`:

```sh
curl -fsSL https://raw.githubusercontent.com/rahulpatel/dotfiles/main/install.sh | PROFILE=personal bash
```

[`install.sh`](install.sh) installs the Command Line Tools, clones this repo to
`~/.dotfiles`, writes `.miserc.local.toml` for the profile, then runs
`mise bootstrap`. Open a new terminal afterwards (the login shell changes to fish).

## Day to day

Run from `~/.dotfiles` (or add `-C ~/.dotfiles`):

| Old | New |
| --- | --- |
| `dot install <profile>` | `mise bootstrap` |
| `dot update` | `mise run upgrade` |
| `dot stow` | `mise dot apply` |
| `dot unstow` / `dot uninstall` | `mise dot unapply` |
| `dot macos` | `mise bootstrap macos defaults apply` |
| `dot doctor` | `mise bootstrap status` |
| `dot profiles` | `grep 'env =' mise.toml` |

Preview anything first with `--dry-run`, e.g. `mise bootstrap --dry-run`.

Adding a dotfile: put it under `home/` and `git add` it, then `mise dot apply`.
Adding a package: `mise bootstrap packages use brew:<name>` (or edit `mise.toml`).

## pi subagents

[`home/.pi/agent/extensions/subagent`](home/.pi/agent/extensions/subagent) adds
a `subagent` tool to pi, modeled on opencode's. Each subagent is a child pi
session saved next to its parent, so it can be resumed by `sessionID`, even
after a restart. Agents are Markdown files in `~/.pi/agent/agents/` or a
project's `.pi/agents/`, plus the built-in `general` and `explore`. Beyond
opencode's inputs, it takes `thinking`, `readonly` (bash runs under
`sandbox-exec` with file writes denied), `worktree`, and `cwd`. Run
`/subagents` to watch a subagent's transcript live, steer it, or abort it.
