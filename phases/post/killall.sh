#!/usr/bin/env bash
# post/killall.sh - restart processes affected by `defaults write` so changes
# take effect without a logout.

log "Restarting affected services"
for app in Dock Finder SystemUIServer cfprefsd; do
    killall "$app" 2>/dev/null || true
done
