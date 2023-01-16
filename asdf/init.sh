#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi

cd "$(dirname "$0")"

main() {
    echo "ℹ️  asdf"

    if [[ ! -x "$(command -v asdf)" ]]; then
        source "$PWD/config.sh"
    fi

    local required_plugins=""
    required_plugins=$(awk <"$PWD/tool-versions.symlink" '{ print $1 }')

    local installed_plugins=""
    installed_plugins=$(asdf plugin list || echo "")

    for plugin in $required_plugins; do
        local filtered_installed_plugin=""
        filtered_installed_plugin=$(echo "$installed_plugins" | grep "$plugin" || echo "")

        if [[ "$plugin" != "$filtered_installed_plugin" ]]; then
            asdf plugin add "$plugin"
        fi
    done

    cd ~
    asdf install

    echo "✅ asdf"
}

main "$@"
