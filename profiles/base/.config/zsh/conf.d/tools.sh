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

# eza - modern ls. Replace ls with sensible defaults; keep `command ls` for
# scripts that pipe its output.
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --group-directories-first'
    alias ll='eza -lah --group-directories-first --git'
    alias la='eza -a --group-directories-first'
    alias tree='eza --tree'
fi

# bat - cat with syntax highlighting. Don't alias `cat` (breaks pipes/scripts);
# use bat explicitly when you want highlighting.
