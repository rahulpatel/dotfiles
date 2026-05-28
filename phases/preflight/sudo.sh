#!/usr/bin/env bash
# preflight/sudo.sh - cache sudo credentials and keep them fresh for the
# duration of the install. Run early so later scripts can call sudo without
# prompting the user mid-install.

log "Caching sudo credentials..."
sudo -v

# Refresh sudo timestamp in the background until this script's parent exits.
# The keepalive process is killed via trap on EXIT.
(
    while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" 2>/dev/null || exit
    done
) &
SUDO_KEEPALIVE_PID=$!

# shellcheck disable=SC2064
trap "kill $SUDO_KEEPALIVE_PID 2>/dev/null || true" EXIT
