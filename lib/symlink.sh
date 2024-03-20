#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi

cd "$(dirname "$0")"

main() {
    local file_path=$(echo ${1/$DOTFILES_ROOT\/})
    local destination=""
 
    if [[ $file_path =~ ^config ]]; then
        mkdir -p "$HOME/.config"
        destination="$HOME/.${file_path/.symlink}"
    else
        destination="$HOME/.$(basename "${1%.*}")"
    fi

    if [[ -a "$destination" ]]; then
	rm "$destination"
    fi

    ln -sf "$1" "$destination"
    echo ">> Linked $1 to $destination"
}

main "$@"
