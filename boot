#!/usr/bin/env bash
# boot - first-time bootstrap for a fresh macOS machine.
#
# Usage (from a fresh machine):
#   curl -fsSL https://raw.githubusercontent.com/<you>/dotfiles/main/boot | bash
#
# Installs prerequisites (Xcode Command Line Tools, Homebrew), clones the
# dotfiles repo to ~/.dotfiles, then hands off to ./install.

set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/rahulpatel/dotfiles.git}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

log() { printf '\033[1;34m[boot]\033[0m %s\n' "$*"; }
die() {
  printf '\033[1;31m[boot]\033[0m %s\n' "$*" >&2
  exit 1
}

# --- Xcode Command Line Tools ---------------------------------------------
# Required for `git` (and for Homebrew, which preflight installs).
if ! xcode-select -p >/dev/null 2>&1; then
  log "Installing Xcode Command Line Tools (a GUI prompt will appear)..."
  xcode-select --install || true
  # Wait until installation completes.
  until xcode-select -p >/dev/null 2>&1; do
    sleep 10
  done
fi

# --- Clone repo ------------------------------------------------------------
if [ ! -d "$DOTFILES_DIR/.git" ]; then
  log "Cloning $DOTFILES_REPO -> $DOTFILES_DIR"
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
else
  log "Repo already present at $DOTFILES_DIR; pulling latest"
  git -C "$DOTFILES_DIR" pull --ff-only
fi

# --- Hand off to installer -------------------------------------------------
# Homebrew installation lives in modules/homebrew.sh so the logic stays in
# one place and direct ./install runs are also self-healing.
log "Handing off to $DOTFILES_DIR/install"
exec "$DOTFILES_DIR/install" "$@"
