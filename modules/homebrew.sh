#!/usr/bin/env bash
# modules/homebrew.sh - install Homebrew, then process the Brewfiles.
#
#   prepare() - install brew if missing, ensure it's on PATH
#   install() - `brew bundle` for base + active profile

prepare() {
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
}

install() {
    local profile brewfile
    for profile in base "$PROFILE"; do
        brewfile="$DOTFILES/profiles/$profile/Brewfile"
        if [ -f "$brewfile" ]; then
            log "brew bundle: profiles/$profile/Brewfile"
            brew bundle --file="$brewfile"
        fi
    done
}
