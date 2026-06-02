#!/usr/bin/env bash
# modules/sudo.sh - cache sudo credentials and keep them fresh for the
# duration of the install so later modules can call sudo without prompting.

prepare() {
    log "Caching sudo credentials..."
    sudo -v

    # Refresh sudo timestamp in the background until the orchestrator exits.
    (
        while true; do
            sudo -n true
            sleep 60
            kill -0 "$$" 2>/dev/null || exit
        done
    ) &
    local pid=$!

    # shellcheck disable=SC2064
    trap "kill $pid 2>/dev/null || true" EXIT
}
