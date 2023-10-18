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

    local repos_folder_path="$HOME/Developer"

    if [[ ! -d "$repos_folder_path" ]]; then
	    mkdir "$repos_folder_path"
    fi

    echo "✅ macos"
}

main "$@"
