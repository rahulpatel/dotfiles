#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi

cd "$(dirname "$0")"

generate_gitconfig() {
    sed -e "s/{AUTHOR_NAME}/$1/g" -e "s/{AUTHOR_EMAIL}/$2/g" "$PWD/git/gitconfig.template" >"$PWD/git/gitconfig.symlink"
}

generate_ssh_key() {
    local ssh_file="$HOME/.ssh/github"

    if [[ -f "$ssh_file" ]]; then
        return
    fi

    ssh-keygen -t ed25519 -C "$1" -P "" -f "$ssh_file"
    eval "$(ssh-agent -s)"

    local ssh_config_file="$HOME/.ssh/config"
    if [[ ! -f "$ssh_config_file" ]]; then
        {
            echo "Host github.com"
            echo "  AddKeysToAgent yes"
            echo "  IdentityFile ~/.ssh/github"
        } >>"$ssh_config_file"
    fi

    pbcopy <"$HOME/.ssh/github.pub"
    cat "$HOME/.ssh/github.pub"
    echo ""
    echo "Go to https://github.com/settings/ssh/new and add the above key (it's already on the clipboard)"
    echo ""
}

main() {
    echo "ℹ️  git"

    if [[ -f "./gitconfig.symlink" ]]; then
        echo "✅ git"
        return
    fi

    echo '> github author name'
    read -r -e git_author_name

    echo '> github author email (<username>@users.noreply.github.com)'
    read -r -e git_author_email

    generate_gitconfig "$git_author_name" "$git_author_email"
    generate_ssh_key "$git_author_email"

    echo "✅ git"
}

main "$@"
