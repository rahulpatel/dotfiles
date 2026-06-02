#!/usr/bin/env bash
# modules/stow.sh - symlink each profile's directory into $HOME.
#
# Each profile (profiles/<name>/) is a stow package. Profile metadata
# (Brewfile, macos.sh) is excluded via the profile's .stow-local-ignore.
#
# Existing non-symlink files at stow targets are backed up to
# ~/.dotfiles-backup/<timestamp>/ before stowing, never overwritten in place.

configure() {
    has stow || die "GNU stow not installed (add to base Brewfile)"

    local backup_ts backup_dir
    backup_ts="$(date +%Y%m%d-%H%M%S)"
    backup_dir="$BACKUP_ROOT/$backup_ts"

    # Ensure shared parent dirs exist as real dirs so stow descends rather
    # than symlinking the whole thing.
    mkdir -p "$HOME/.config"

    local profile
    for profile in base "$PROFILE"; do
        _stow_profile "$profile" "$backup_dir"
    done
}

_stow_profile() {
    local profile="$1"
    local backup_dir="$2"
    local src="$DOTFILES/profiles/$profile"
    [ -d "$src" ] || return 0

    local file rel target
    while IFS= read -r -d '' file; do
        rel="${file#$src/}"
        case "$rel" in
            Brewfile|macos.sh|.stow-local-ignore) continue ;;
        esac
        target="$HOME/$rel"
        if [ -e "$target" ] && [ ! -L "$target" ]; then
            mkdir -p "$backup_dir/$(dirname "$rel")"
            warn "Backing up conflicting $target -> $backup_dir/$rel"
            mv "$target" "$backup_dir/$rel"
        fi
    done < <(find "$src" -type f -print0)

    log "stow: profiles/$profile"
    # --no-folding: never collapse a target dir into a symlink to the package
    # dir. Keeps stowed config dirs as real dirs so tools can safely write
    # runtime state inside them (e.g. tmux plugins, mise installs) without
    # writing into the dotfiles repo.
    stow --no-folding --dir="$DOTFILES/profiles" --target="$HOME" --restow "$profile"
}
