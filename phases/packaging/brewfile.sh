#!/usr/bin/env bash
# packaging/brewfile.sh - install everything declared in the base and active
# profile Brewfiles. `brew bundle` is idempotent: re-running is a no-op for
# already-installed packages.

for profile in base "$PROFILE"; do
    brewfile="$DOTFILES/profiles/$profile/Brewfile"
    if [ -f "$brewfile" ]; then
        log "brew bundle: profiles/$profile/Brewfile"
        brew bundle --file="$brewfile"
    fi
done
