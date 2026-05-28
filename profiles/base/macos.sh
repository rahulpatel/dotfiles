#!/usr/bin/env bash
# profiles/base/macos.sh - macOS defaults applied on every machine.
#
# Sourced by phases/config/macos.sh. Strict mode and helpers are inherited.
# Do NOT killall here; phases/post/killall.sh handles restarts centrally.

# Examples (uncomment and adjust):

# --- Keyboard --------------------------------------------------------------
# defaults write NSGlobalDomain KeyRepeat -int 2
# defaults write NSGlobalDomain InitialKeyRepeat -int 15

# --- Finder ----------------------------------------------------------------
# defaults write com.apple.finder AppleShowAllFiles -bool true
# defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# --- Dock ------------------------------------------------------------------
# defaults write com.apple.dock autohide -bool true
# defaults write com.apple.dock tilesize -int 48
