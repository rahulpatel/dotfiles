#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi

if [[ "${1-}" =~ ^-*h(elp)?$ ]]; then
    echo '
Usage: ./init.sh

Setup a new MacOS install just the way I like it.
'
    exit
fi

cd "$(dirname "$0")"

symlink_files() {
    echo "ℹ️ symlink files"

    local files_to_symlink=""
    files_to_symlink=$(bash "$PWD/lib/find.sh" "*.symlink")

    bash "$PWD/lib/symlink.sh $files_to_symlink"

    echo "✅ symlinked files"
}

main() {
    echo 'ℹ️ dotfiles'

    echo ""
    bash "$PWD/macos/init.sh"
    echo ""

    echo ""
    bash "$PWD/homebrew/init.sh"
    echo ""

    echo ""
    bash "$PWD/git/init.sh"
    echo ""

    echo ""
    symlink_files
    echo ""

    echo ""
    bash "$PWD/asdf/init.sh"
    echo ""

    echo ""
    bash "$PWD/zsh/init.sh"
    echo ""

    echo '✅ dotfiles'
}

main "$@"
