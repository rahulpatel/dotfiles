# dotfiles

Bootstraps a macOS machine into my preferred state: packages, apps, dotfiles,
and macOS defaults — all in one command, idempotently.

## Bootstrap a fresh machine

```sh
curl -fsSL https://raw.githubusercontent.com/rahulpatel/dotfiles/v2/boot | bash
```

The `boot` script installs Xcode Command Line Tools, installs Homebrew, clones
this repo to `~/.dotfiles`, and runs `./install`.

## Re-run on an existing machine

```sh
cd ~/.dotfiles
./install
```

Idempotent: re-running is safe. Existing non-symlink files at stow targets are
backed up to `~/.dotfiles-backup/<timestamp>/` before being replaced.

## Profiles

A profile is selected on first run and persisted in `.profile` (gitignored):

```sh
PROFILE=personal ./install   # or: PROFILE=work
```

Subsequent runs read the persisted profile. Override anytime by setting the
env var again.

Each profile under `profiles/<name>/` IS a stow package. It mirrors `$HOME`
directly, plus a few profile-metadata files (`Brewfile`, `macos.sh`) that
the install pipeline reads but which are excluded from stowing via
`.stow-local-ignore`. The `base` profile is applied on every machine; the
active profile is applied on top.

## Structure

```
.
├── boot                # curl|bash entry for fresh machines
├── install             # orchestrator: phases × modules
├── modules/
│   ├── _lib.sh         # shared helpers (skipped by orchestrator)
│   ├── sudo.sh         # prepare()
│   ├── xcode.sh        # prepare()
│   ├── homebrew.sh     # prepare() + install()
│   ├── macos.sh        # configure()
│   ├── mise.sh         # configure()
│   ├── stow.sh         # configure()
│   ├── killall.sh      # finish()
│   └── summary.sh      # finish()
└── profiles/
    ├── base/                  # applied on every machine
    │   ├── Brewfile           # \
    │   ├── macos.sh           # / profile metadata (not stowed)
    │   ├── .stow-local-ignore # tells stow which files above to skip
    │   ├── .config/           # everything else is stowed into $HOME
    │   │   ├── git/
    │   │   └── zsh/
    │   └── .zshenv
    ├── work/
    └── personal/
```

Each file in `modules/` is one step of the install pipeline. It defines
whichever of `preflight()`, `packaging()`, `config()`, `post()` apply — most
modules have just one. The orchestrator iterates phases in declared order
and, within each phase, runs every module's matching function in alphabetical
order. Scripts within a phase are independent: if two need to be ordered,
move one to a different phase.

To add or modify a tool, edit one file in `modules/`. No need to know which
phase it belongs to — the function name says it.

## Secrets

Secrets and sensitive config are kept out of this (public) repo and restored
out-of-band on each new machine:

- SSH keys, GPG keys, API tokens — restored manually
- Work git identity and routing — `~/.gitconfig.local` holds the
  `includeIf` directives (employer org name, work paths), `~/.gitconfig.work`
  holds the work `[user]` block. Both are out-of-band; neither enters the
  repo. The committed `base/dotfiles/git/.gitconfig` unconditionally includes
  `~/.gitconfig.local`, so its presence (or absence) controls work routing.
- Any tool with a sensitive override — keep the public part in the repo, point
  it at a `~/.<tool>.local` file that is restored out-of-band

This way, commits to *this* repo (a personal project) use the personal
identity even when made from a work machine.

## Adding a tool

1. Add it to the appropriate `Brewfile` (base, or a specific profile).
2. If it has dotfiles, drop them into the matching profile mirroring `$HOME`
   — e.g. `profiles/base/.config/<tool>/`.
3. If it needs shell init, drop a script under the matching profile's
   `.config/zsh/`: `env.d/<tool>.sh` for env vars / PATH (runs in every
   subshell), or `conf.d/<tool>.sh` for interactive setup like
   `eval $(tool init)`.
4. Re-run `./install`.

Stow folds at the directory level: a new `.config/<tool>/` directory in the
repo becomes a single `~/.config/<tool>` symlink. Apps that later write into
their config dir write into the repo dir — useful for some tools, undesirable
for any whose runtime state shouldn't be committed (gh auth tokens, etc.).
For those, link individual files instead by giving each its own subdir, or
add the offending paths to `.gitignore` inside the repo.
