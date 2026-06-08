# tools - shell integration for CLI tools installed via brew.
# Each block is independent; missing tools are silently skipped.

# fzf - fuzzy finder. Binds Ctrl-R (history), Ctrl-T (files), Alt-C (cd).
if command -v fzf >/dev/null 2>&1; then
    source <(fzf --zsh)
fi

# zoxide - smarter cd. `z foo` jumps to most-visited dir matching foo.
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# bat - cat with syntax highlighting. Don't alias `cat` (breaks pipes/scripts);
# use bat explicitly when you want highlighting.
