#!/usr/bin/env bash
# config/mise.sh - install runtimes declared in the stowed mise config.
# Assumes mise is installed via Brewfile and its config has been stowed.

if ! has mise; then
    warn "mise not installed; skipping runtime install (add to base Brewfile)"
    return 0 2>/dev/null || exit 0
fi

if [ -f "$HOME/.config/mise/config.toml" ]; then
    log "mise install"
    mise install
else
    log "no ~/.config/mise/config.toml; skipping mise install"
fi
