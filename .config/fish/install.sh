#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi

cd "$(dirname "$0")"

main() {
    local fish_path=$(brew --prefix fish)
    echo "$fish_path" | sudo tee -a /etc/shells
    chsh -s "$fish_path"
}

main "$@"
