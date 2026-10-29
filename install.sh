#!/usr/bin/env bash
# One-shot setup for a brand new Mac.
#   curl -fsSL https://raw.githubusercontent.com/rahulpatel/dotfiles/main/install.sh | PROFILE=personal bash
set -euo pipefail

PROFILE="${PROFILE:?set PROFILE=personal or PROFILE=work}"
REPO="${REPO:-https://github.com/rahulpatel/dotfiles.git}"
DEST="${DEST:-$HOME/.dotfiles}"

# Ask for the password once up front, and keep sudo alive while we work.
sudo -v
while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &

# Command Line Tools (git) without the GUI prompt.
if ! xcode-select -p >/dev/null 2>&1; then
  echo "==> Installing Command Line Tools"
  marker=/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
  touch "$marker"
  label="$(softwareupdate -l 2>/dev/null | sed -n 's/^\* Label: \(Command Line Tools.*\)/\1/p' | sort -V | tail -1)"
  sudo softwareupdate -i "$label" --verbose
  rm -f "$marker"
fi

if [ ! -d "$DEST/.git" ]; then
  echo "==> Cloning $REPO"
  git clone "$REPO" "$DEST"
fi
cd "$DEST"
[ -f .miserc.local.toml ] || echo "env = [\"$PROFILE\"]" > .miserc.local.toml

# Install mise (to ~/.local/bin) the recommended way.
curl -fsSL https://mise.run | sh
export PATH="$HOME/.local/bin:$PATH"
mise trust
mise bootstrap --yes

echo "==> Done. Open a new terminal (login shell is now fish)."
