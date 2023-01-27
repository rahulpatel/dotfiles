#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi

cd "$(dirname "$0")"

main() {
    echo "ℹ️  podman"

    # Let podman setup a docker socket
    sudo podman-mac-helper install

    echo "✅ podman"
}

main "$@"
