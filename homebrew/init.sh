#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi

cd "$(dirname "$0")"

main() {
    echo "ℹ️ homebrew"

    if [[ ! -x "$(command -v brew)" ]]; then
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        bash "$PWD/config.sh"
    fi

    brew update
    brew bundle --file="$PWD/Brewfile"
    brew cleanup

    echo "✅ homebrew"
}

main "$@"
