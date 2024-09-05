#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi

cd "$(dirname "$0")"

main() {
    local CONFIGDIR="$PWD/.config"

    echo "setup macos"
    /bin/bash "$CONFIGDIR/macos/install.sh"


    echo "setup homebrew"
    /bin/bash "$CONFIGDIR/homebrew/install.sh"

    # activate homebrew in this session
    source "$PWD/.config/homebrew/config.sh"

    stow -v .

    local install_files=$(find "$CONFIGDIR" -name "install.sh" ! -path "*macos*" ! -path "*homebrew*" ! -path "*zsh*")
    for file in $install_files; do
        echo "setup $file"
        /bin/bash "$file"
    done

    echo ""
    echo "Restart the machine"
}

main "$@"
