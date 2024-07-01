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
    echo "ℹ️  symlink files"

    local files_to_symlink=""
    files_to_symlink=$(bash "$PWD/lib/find.sh" "*.symlink")

    for file in $files_to_symlink; do
        source "$PWD/lib/symlink.sh" "$file"
    done

    echo "✅ symlinked files"
}

main() {
    echo 'ℹ️  dotfiles'

    echo ""
    source "$PWD/macos/init.sh"
    echo ""

    echo ""
    source "$PWD/homebrew/init.sh"
    source "$PWD/homebrew/config.sh"
    echo ""

    #echo ""
    #source "$PWD/pkgx/init.sh"
    #source "$PWD/pkgx/config.sh"
    #echo ""

    echo ""
    source "$PWD/git/init.sh"
    echo ""

    echo ""
    symlink_files
    echo ""

    echo ""
    source "$PWD/tmux/init.sh"
    echo ""

    echo ""
    source "$PWD/zsh/init.sh"
    echo ""

    echo "🚀 machine is ready, retart the terminal"
}

main "$@"
