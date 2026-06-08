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
    # than symlinking the whole thing. $HOME/.config and $HOME/.local/bin must
    # stay real dirs so multiple tools/profiles can coexist; stow then folds
    # each per-tool subdir (e.g. .config/nvim) into a single symlink pointing
    # at the package dir. If a tool writes runtime state into its config dir
    # (e.g. tmux/TPM plugins or television's downloaded channel prototypes),
    # pre-create that specific dir after unstowing so stow descends into it
    # instead of folding.
    mkdir -p "$HOME/.config"

    # Unstow first so existing stow-managed symlinks (both per-file legacy
    # links and folded dir links like ~/.config/nvim) are removed. This is
    # critical before backing up: if we backed up first, paths like
    # ~/.config/nvim/init.lua would resolve *through* the folded parent
    # symlink into the repo, and mv would yank the real file out of the
    # repo. Unstowing first leaves only genuine user-owned files behind.
    local profile
    for profile in base "$PROFILE"; do
        _unstow_profile "$profile"
    done
    _prune_empty_config_dirs
    mkdir -p "$HOME/.config/television/cable" "$HOME/.local/bin"

    # Now back up any remaining non-symlink conflicts across all profiles.
    for profile in base "$PROFILE"; do
        _backup_conflicts "$profile" "$backup_dir"
    done

    for profile in base "$PROFILE"; do
        _stow_profile "$profile"
    done
}

_backup_conflicts() {
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
        # Skip if target itself is a symlink, or if any parent component is
        # a symlink. The latter guards against folded stow dirs (e.g.
        # ~/.config/nvim -> repo): without this, mv would follow the parent
        # symlink and move the real file out of the repo.
        if [ -e "$target" ] && [ ! -L "$target" ] && ! _parent_is_symlink "$target"; then
            mkdir -p "$backup_dir/$(dirname "$rel")"
            warn "Backing up conflicting $target -> $backup_dir/$rel"
            mv "$target" "$backup_dir/$rel"
        fi
    done < <(find "$src" -type f -print0)
}

# Walk up parents of $1 (stopping at $HOME) and return 0 if any is a symlink.
_parent_is_symlink() {
    local dir
    dir="$(dirname "$1")"
    while [ "$dir" != "$HOME" ] && [ "$dir" != "/" ]; do
        [ -L "$dir" ] && return 0
        dir="$(dirname "$dir")"
    done
    return 1
}

_unstow_profile() {
    local profile="$1"
    [ -d "$DOTFILES/profiles/$profile" ] || return 0
    # Ignore failures: a never-stowed profile has nothing to delete.
    stow --dir="$DOTFILES/profiles" --target="$HOME" --delete "$profile" 2>/dev/null || true
}

# Remove empty per-tool dirs under $HOME/.config left behind by the legacy
# --no-folding layout. Only touches dirs whose entire subtree is empty, so
# user-owned dirs with real files (e.g. nvim's lazy-lock.json, tmux/plugins)
# are preserved -- they'll just remain unfolded.
_prune_empty_config_dirs() {
    [ -d "$HOME/.config" ] || return 0
    find "$HOME/.config" -mindepth 1 -depth -type d -empty -delete 2>/dev/null || true
}

_stow_profile() {
    local profile="$1"
    [ -d "$DOTFILES/profiles/$profile" ] || return 0
    log "stow: profiles/$profile"
    # Default folding: stow collapses a target dir into a single symlink to
    # the package dir when nothing else lives there. Pre-created real dirs
    # (e.g. $HOME/.config) and dirs containing runtime state stay descended.
    stow --dir="$DOTFILES/profiles" --target="$HOME" --stow "$profile"
}
