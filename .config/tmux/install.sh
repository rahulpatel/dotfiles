#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi

cd "$(dirname "$0")"

main() {
    if [[ ! -d "$PWD/plugins/tpm" ]]; then
        git clone https://github.com/tmux-plugins/tpm "$PWD/plugins/tpm"
    fi
}

main "$@"
