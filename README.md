# dotfiles

My macOS setup completely managed by mise.

## Profiles

Profile-specific packages use `env = "<profile>"`. Each machine picks its
profile in `.miserc.local.toml` (not committed):

```toml
env = ["personal"] # or ["work"]
```

## New machine

Paste this into Terminal on a fresh Mac, enter your password once, answer the
prompts and walk away.

Set `PROFILE` to `personal` or `work`:

```sh
curl -fsSL https://raw.githubusercontent.com/rahulpatel/dotfiles/main/install.sh | PROFILE=personal bash
```

[`install.sh`](install.sh) installs the Command Line Tools, clones this repo to
`~/.dotfiles`, writes `.miserc.local.toml` for the profile, then runs
`mise bootstrap`. Open a new terminal afterwards (the login shell changes to fish).
