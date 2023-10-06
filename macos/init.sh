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

<<<<<<< Updated upstream
    local code_folder_path="$HOME/Developer"

    if [[ -d "$code_folder_path" ]]; then
        echo "> repositories volume already exists"
        exit
    fi

    if [[ ! -d "$code_folder_path" ]]; then
        mkdir "$code_folder_path"
    fi

    # local repo_volume_name="Repositories"
    # local repo_symlink_name="Developer"

    # local repo_volume_path="/Volumes/$repo_volume_name"
    # local repo_symlink_path="$HOME/$repo_symlink_name"

    # if [[ -d "$repo_volume_path" ]]; then
    #     echo "> repositories volume already exists"
    #     exit
    # fi

    # diskutil list
    # echo '> which disk should the volume be added to?'
    # read -r -e disk_name

    # if [[ $disk_name == "" ]]; then
    #     echo '> disk name not provided'
    #     exit 1
    # fi

    # diskutil apfs addVolume "$disk_name" "Case-sensitive APFS" "$repo_volume_name" -passprompt

    # if [[ ! -L "$repo_symlink_path" ]]; then
    #     mkdir "$repo_symlink_path"
    #     ln -s "$repo_volume_path" "$repo_symlink_path"
    # fi
=======
    local repos_folder_path="$HOME/Developer"

    if [[ -d "$repos_folder_path" ]]; then
        echo "> path \"$repos_folder_path\" already exists"
    fi

    mkdir "$repos_folder_path"
>>>>>>> Stashed changes

    echo "✅ macos"
}

main "$@"
