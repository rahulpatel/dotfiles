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
    # than symlinking the whole thing. $HOME/.config must stay a real dir so
    # multiple tools (and both profiles) can coexist under it; stow then folds
    # each per-tool subdir (e.g. .config/nvim) into a single symlink pointing
    # at the package dir. If a tool writes runtime state into its config dir
    # (e.g. tmux/TPM plugins under .config/tmux/plugins), pre-create that
    # specific dir here so stow descends into it instead of folding.
    mkdir -p "$HOME/.config"

    # Back up any conflicting non-symlink targets across all profiles first.
    local profile
    for profile in base "$PROFILE"; do
        _backup_conflicts "$profile" "$backup_dir"
    done

    # Unstow first so existing per-file symlinks (legacy --no-folding layout)
    # are removed. Then prune the empty per-tool dirs they leave behind so
    # the subsequent stow pass can fold each subdir into a single symlink.
    for profile in base "$PROFILE"; do
        _unstow_profile "$profile"
    done
    _prune_empty_config_dirs

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
        if [ -e "$target" ] && [ ! -L "$target" ]; then
            mkdir -p "$backup_dir/$(dirname "$rel")"
            warn "Backing up conflicting $target -> $backup_dir/$rel"
            mv "$target" "$backup_dir/$rel"
        fi
    done < <(find "$src" -type f -print0)
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
