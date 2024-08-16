#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi

cd "$(dirname "$0")"

main() {
    if [[ ! -d "$PWD/antidote" ]]; then
        git clone --depth=1 https://github.com/mattmc3/antidote.git "$PWD/antidote"
    fi
}

main "$@"
