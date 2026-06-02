#!/usr/bin/env bash
# modules/macos.sh - apply macOS defaults from base and active profile.
#
# Each profile's macos.sh is sourced (not executed) so it inherits strict mode
# and helpers from _lib.sh. Restarts of affected processes are centralised in
# modules/killall.sh, so individual scripts should not killall themselves.

configure() {
    local profile f
    for profile in base "$PROFILE"; do
        f="$DOTFILES/profiles/$profile/macos.sh"
        if [ -f "$f" ]; then
            log "macos defaults: profiles/$profile/macos.sh"
            # shellcheck source=/dev/null
            source "$f"
        fi
    done
}
