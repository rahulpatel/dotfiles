#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi

cd "$(dirname "$0")"

main() {
    echo "> symlink files"

    for file in "$@"; do
        local destination=""
        destination="$HOME/.$(basename "${file%.*}")"

        if [[ -f "$destination" ]]; then
            rm "$destination"
        fi

        ln -s "$file" "$destination"
    done
}

main "$@"
