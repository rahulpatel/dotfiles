#!/usr/bin/env bash
# modules/tmux.sh - install tpm (tmux plugin manager) and sync plugins
# declared in the stowed tmux config.

configure() {
  if ! has tmux; then
    warn "tmux not installed; skipping plugin setup (add to base Brewfile)"
    return 0
  fi

  local tpm="$HOME/.config/tmux/plugins/tpm"
  if [ ! -d "$tpm" ]; then
    log "tmux: installing tpm"
    git clone https://github.com/tmux-plugins/tpm "$tpm"
  fi

  log "tmux: installing plugins"
  "$tpm/bin/install_plugins"
}
