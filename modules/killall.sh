#!/usr/bin/env bash
# modules/killall.sh - restart processes affected by `defaults write` so
# changes take effect without a logout.

finish() {
    log "Restarting affected services"
    local app
    for app in Dock Finder SystemUIServer cfprefsd; do
        killall "$app" 2>/dev/null || true
    done
}
