#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi

cd "$(dirname "$0")"

main() {
    local destination=""
    destination="$HOME/.$(basename "${1%.*}")"
    ln -sf "$1" "$destination"
}

main "$@"
