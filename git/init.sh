#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi

cd "$(dirname "$0")"

main() {
    echo "ℹ️ git"

    echo '> github author name'
    read -r -e git_author_name

    echo '> github author email (<username>@users.noreply.github.com)'
    read -r -e git_author_email

    sed -e "s/{AUTHOR_NAME}/$git_author_name/g" -e "s/{AUTHOR_EMAIL}/$git_author_email/g" "$PWD/gitconfig.template" >"$PWD/gitconfig.symlink"

    echo "✅ git"
}

main "$@"
