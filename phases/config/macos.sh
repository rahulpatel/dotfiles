#!/usr/bin/env bash
# config/macos.sh - apply macOS defaults from base and active profile.
#
# Each profile's macos.sh is sourced (not executed) so it inherits strict mode
# and helpers from lib.sh. Restarts of affected processes are centralised in
# phases/post/killall.sh, so individual scripts should not killall themselves.

for profile in base "$PROFILE"; do
    f="$DOTFILES/profiles/$profile/macos.sh"
    if [ -f "$f" ]; then
        log "macos defaults: profiles/$profile/macos.sh"
        # shellcheck source=/dev/null
        source "$f"
    fi
done
