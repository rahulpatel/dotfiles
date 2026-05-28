#!/usr/bin/env bash
# config/stow.sh - symlink dotfiles from base and the active profile into $HOME.
#
# Each profile has a single `dotfiles/` package mirroring $HOME. Stow's
# tree-folding produces per-directory symlinks (e.g., ~/.config/git ->
# repo/.../.config/git), so apps creating new entries under ~/.config never
# end up inside this repo.
#
# Existing non-symlink files at stow targets are backed up to
# ~/.dotfiles-backup/<timestamp>/ before stowing, never overwritten in place.

has stow || die "GNU stow not installed (add to base Brewfile)"

backup_ts="$(date +%Y%m%d-%H%M%S)"
backup_dir="$BACKUP_ROOT/$backup_ts"

# Ensure shared parent directories exist as real directories before stowing.
# Without this, stow would fold the entire ~/.config into a single symlink
# pointing at the repo, capturing every app's runtime state under git.
mkdir -p "$HOME/.config"

stow_profile() {
    local profile="$1"
    local src="$DOTFILES/profiles/$profile"
    [ -d "$src/dotfiles" ] || return 0

    # Back up non-symlink file conflicts before stowing.
    while IFS= read -r -d '' file; do
        local rel="${file#$src/dotfiles/}"
        local target="$HOME/$rel"
        if [ -e "$target" ] && [ ! -L "$target" ]; then
            mkdir -p "$backup_dir/$(dirname "$rel")"
            warn "Backing up conflicting $target -> $backup_dir/$rel"
            mv "$target" "$backup_dir/$rel"
        fi
    done < <(find "$src/dotfiles" -type f -print0)

    log "stow: profiles/$profile/dotfiles"
    stow --dir="$src" --target="$HOME" --restow dotfiles
}

for profile in base "$PROFILE"; do
    stow_profile "$profile"
done
