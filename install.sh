#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi

cd "$(dirname "$0")"

main() {
    xcode-select --install

    local CONFIGDIR="$PWD/.config"

    /bin/bash "$CONFIGDIR/macos/install.sh"
    /bin/bash "$CONFIGDIR/zsh/install.sh"
    /bin/bash "$CONFIGDIR/homebrew/install.sh"

    # activate homebrew in this session
    source "$PWD/.config/homebrew/config.sh"

    local install_files=$(find "$CONFIGDIR" -name "install.sh" ! -path "*macos*" ! -path "*homebrew*" ! -path "*zsh*")
    for file in $install_files; do
       /bin/bash "$file"
    done
}

main "$@"
