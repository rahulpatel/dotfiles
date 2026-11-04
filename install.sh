#!/usr/bin/env bash
set -euo pipefail

PROFILE="${PROFILE:?set PROFILE=personal or PROFILE=work}"
case "$PROFILE" in
  personal|work) ;;
  *) echo "PROFILE must be personal or work" >&2; exit 1 ;;
esac

REPO="${REPO:-https://github.com/rahulpatel/dotfiles.git}"
DEST="${DEST:-$HOME/.dotfiles}"

sudo_pid=""
marker=""
cleanup() {
  if [ -n "$sudo_pid" ]; then
    kill "$sudo_pid" 2>/dev/null || true
    wait "$sudo_pid" 2>/dev/null || true
  fi
  if [ -n "$marker" ]; then
    rm -f "$marker"
  fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

sudo -v
while sleep 50; do sudo -n true || exit; done 2>/dev/null &
sudo_pid=$!

if ! xcode-select -p >/dev/null 2>&1; then
  echo "==> Installing Command Line Tools"
  marker=/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
  touch "$marker"
  label="$(softwareupdate -l 2>/dev/null | sed -n 's/^\* Label: \(Command Line Tools.*\)/\1/p' | sort -V | tail -1)"
  sudo softwareupdate -i "$label" --verbose
  rm -f "$marker"
  marker=""
fi

if [ ! -d "$DEST/.git" ]; then
  echo "==> Cloning $REPO"
  git clone "$REPO" "$DEST"
fi
cd "$DEST"
if [ -f .miserc.local.toml ]; then
  echo "==> Keeping existing profile in $DEST/.miserc.local.toml (PROFILE=$PROFILE does not override it)"
else
  printf 'env = ["%s"]\n' "$PROFILE" > .miserc.local.toml
fi

# Install mise (to ~/.local/bin) the recommended way.
curl -fsSL https://mise.run | sh
export PATH="$HOME/.local/bin:$PATH"
mise trust
mise bootstrap --yes --prompt-vars

echo "==> Done. Open a new terminal (login shell is now fish)."
