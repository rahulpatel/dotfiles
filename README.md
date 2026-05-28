# dotfiles

Bootstraps a macOS machine into my preferred state: packages, apps, dotfiles,
and macOS defaults — all in one command, idempotently.

## Bootstrap a fresh machine

```sh
curl -fsSL https://raw.githubusercontent.com/CHANGE_ME/dotfiles/main/boot | bash
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

Each profile under `profiles/<name>/` contributes a `Brewfile`, a stowable
`dotfiles/` tree mirroring `$HOME`, and a `macos.sh`. The `base` profile is
applied on every machine; the active profile is applied on top.

## Structure

```
.
├── boot                # curl|bash entry for fresh machines
├── install             # orchestrator: runs each phase in order
├── phases/
│   ├── lib.sh          # shared: strict mode, logging
│   ├── preflight/      # sudo, xcode CLT, homebrew
│   ├── packaging/      # brew bundle base + active profile
│   ├── config/         # stow, macos defaults, mise runtimes
│   └── post/           # killall, summary
└── profiles/
    ├── base/           # applied on every machine
    │   ├── Brewfile
    │   ├── dotfiles/   # mirrors $HOME; XDG-friendly
    │   │   └── .config/
    │   │       └── git/
    │   └── macos.sh
    ├── work/
    └── personal/
```

Phases run in the order declared in `install`. Scripts within a phase are
sourced in alphabetical order and should be order-independent — if two
scripts depend on each other, split them across phases.

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
2. If it has dotfiles, drop them in the matching profile's `dotfiles/` tree
   mirroring `$HOME` — e.g. `profiles/base/dotfiles/.config/<tool>/`.
3. Re-run `./install`.

Stow folds at the directory level: a new `.config/<tool>/` directory in the
repo becomes a single `~/.config/<tool>` symlink. Apps that later write into
their config dir write into the repo dir — useful for some tools, undesirable
for any whose runtime state shouldn't be committed (gh auth tokens, etc.).
For those, link individual files instead by giving each its own subdir, or
add the offending paths to `.gitignore` inside the repo.
