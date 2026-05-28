#!/usr/bin/env bash
# preflight/homebrew.sh - install Homebrew if missing, then ensure it's on PATH
# for the rest of this run. Idempotent: re-running is a no-op when brew exists.

if ! has brew; then
    if [ ! -x /opt/homebrew/bin/brew ] && [ ! -x /usr/local/bin/brew ]; then
        log "Installing Homebrew..."
        NONINTERACTIVE=1 /bin/bash -c \
            "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

has brew || die "Homebrew install failed; brew not on PATH"
