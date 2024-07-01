#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi

cd "$(dirname "$0")"

main() {
    echo "ℹ️  macos"

    mkdir -p "$HOME/Developer"

    # Set system defaults
    source "$PWD/macos/defaults.sh"

    echo "✅ macos"
}

main "$@"
