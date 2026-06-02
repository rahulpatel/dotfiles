#!/usr/bin/env bash
# modules/_lib.sh - shared helpers. Files starting with _ are skipped by the
# orchestrator and not treated as modules.

# Strict mode. Inherited by sourced module files.
set -euo pipefail
IFS=$'\n\t'

# --- Colours / logging -----------------------------------------------------
if [ -t 1 ]; then
    _C_RESET=$'\033[0m'
    _C_BLUE=$'\033[1;34m'
    _C_YELLOW=$'\033[1;33m'
    _C_RED=$'\033[1;31m'
else
    _C_RESET=''; _C_BLUE=''; _C_YELLOW=''; _C_RED=''
fi

log()  { printf '%s[dotfiles]%s %s\n' "$_C_BLUE"   "$_C_RESET" "$*"; }
warn() { printf '%s[dotfiles]%s %s\n' "$_C_YELLOW" "$_C_RESET" "$*" >&2; }
die()  { printf '%s[dotfiles]%s %s\n' "$_C_RED"    "$_C_RESET" "$*" >&2; exit 1; }

# True if `$1` is an executable on PATH.
has() { command -v "$1" >/dev/null 2>&1; }

# --- Paths -----------------------------------------------------------------
# DOTFILES is set by the orchestrator before sourcing this file.
: "${DOTFILES:?DOTFILES must be set by the orchestrator}"

PROFILE_FILE="$DOTFILES/.profile"
BACKUP_ROOT="$HOME/.dotfiles-backup"
