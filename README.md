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
| Vite+, Rex skill, skills, Caps Lock → Esc | `[tasks.bootstrap]` and `setup:*` tasks |
| [pstack](https://github.com/cursor/plugins/tree/main/pstack) skills for pi and opencode | [`pstack/`](pstack) and `setup:pstack` |

## Profiles

Profile-specific packages use `env = "<profile>"`. Each machine picks its
profile in `.miserc.local.toml` (not committed):

```toml
env = ["personal"] # or ["work"]
```

## New machine

```sh
xcode-select --install   # git; wait for it to finish
git clone https://github.com/rahulpatel/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
echo 'env = ["personal"]' > .miserc.local.toml

# Temporary mise; bootstrap installs the real one from brew:mise.
curl -fsSL https://mise.run | MISE_INSTALL_PATH=/tmp/mise sh
/tmp/mise trust
/tmp/mise bootstrap
```

Open a new terminal afterwards (the login shell changes to fish).

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

## pstack

`mise run setup:pstack` installs pstack at the commit in `PSTACK_REF`
(`mise.toml`) into `~/.local/share/pstack`, and adds its subagents to pi and
opencode. It copies everything the plugin ships, including every skill and the
optional packs, so an update never drops one. To update, change `PSTACK_REF` and
run it again. pstack is written for Cursor;
[`pstack/harness.md`](pstack/harness.md) maps its Cursor names to pi and opencode.

Run `setup-pstack` once per machine, and again when your providers change. It
writes the model for each role to `~/.agents/pstack-models.md` (not committed).
Then start tasks with `/skill:poteto-mode` in pi or `@poteto-mode` in opencode.

## pi subagents

[`home/.pi/agent/extensions/subagent`](home/.pi/agent/extensions/subagent) adds
a `subagent` tool to pi, modeled on opencode's. Each subagent is a child pi
session saved next to its parent, so it can be resumed by `sessionID`, even
after a restart. Agents are Markdown files in `~/.pi/agent/agents/` or a
project's `.pi/agents/`, plus the built-in `general` and `explore`. Beyond
opencode's inputs, it takes `thinking`, `readonly` (bash runs under
`sandbox-exec` with file writes denied), `worktree`, and `cwd`. Run
`/subagents` to watch a subagent's transcript live, steer it, or abort it.
