#!/usr/bin/env bash
# modules/television.sh - update television's downloaded channel prototypes.
# Custom channels are stowed from the active profile.

configure() {
  if ! has tv; then
    warn "tv not installed; skipping television channel update (add to base Brewfile)"
    return 0
  fi

  log "television configure"
  tv update-channels
}
