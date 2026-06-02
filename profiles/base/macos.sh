#!/usr/bin/env bash
# profiles/base/macos.sh - macOS defaults applied on every machine.
#
# Sourced by modules/macos.sh. Strict mode and helpers are inherited.
# Do NOT killall here; modules/killall.sh handles restarts centrally.
#
# All settings start commented out. Uncomment what you want.
# Reference: https://macos-defaults.com

# --- Global UI -------------------------------------------------------------
# Disable the "Are you sure you want to open this application?" dialog.
# defaults write com.apple.LaunchServices LSQuarantine -bool false

# Expand save / print panels by default.
# defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
# defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true

# Disable automatic capitalisation, smart dashes, smart quotes, auto-correct.
# defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
# defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
# defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
# defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# --- Keyboard --------------------------------------------------------------
# Fast key repeat. 2 = 30ms repeat, 15 = 225ms initial.
# defaults write NSGlobalDomain KeyRepeat -int 2
# defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Disable press-and-hold for accented characters (enables key repeat in apps).
# defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Use function keys as standard F-keys.
# defaults write NSGlobalDomain com.apple.keyboard.fnState -bool true

# --- Trackpad --------------------------------------------------------------
# Tap to click.
# defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
# defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
# defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# --- Finder ----------------------------------------------------------------
# Show hidden files and all filename extensions.
# defaults write com.apple.finder AppleShowAllFiles -bool true
# defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show path bar and status bar.
# defaults write com.apple.finder ShowPathbar -bool true
# defaults write com.apple.finder ShowStatusBar -bool true

# Search the current folder by default.
# defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Don't write .DS_Store on network or USB volumes.
# defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
# defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Keep folders on top when sorting.
# defaults write com.apple.finder _FXSortFoldersFirst -bool true

# --- Dock ------------------------------------------------------------------
# Auto-hide, fast.
# defaults write com.apple.dock autohide -bool true
# defaults write com.apple.dock autohide-delay -float 0
# defaults write com.apple.dock autohide-time-modifier -float 0.15

# Tile size + no recent apps.
# defaults write com.apple.dock tilesize -int 48
# defaults write com.apple.dock show-recents -bool false

# Don't rearrange Spaces based on most recent use.
# defaults write com.apple.dock mru-spaces -bool false

# --- Screenshots -----------------------------------------------------------
# Save screenshots to ~/Screenshots as PNG without window shadows.
# mkdir -p "$HOME/Screenshots"
# defaults write com.apple.screencapture location -string "$HOME/Screenshots"
# defaults write com.apple.screencapture type -string "png"
# defaults write com.apple.screencapture disable-shadow -bool true

# --- Safety / misc ---------------------------------------------------------
# Require password immediately after sleep / screensaver.
# defaults write com.apple.screensaver askForPassword -int 1
# defaults write com.apple.screensaver askForPasswordDelay -int 0
