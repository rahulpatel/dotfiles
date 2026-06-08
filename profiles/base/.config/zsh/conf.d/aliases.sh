# aliases - interactive shell shortcuts.

# eza - modern ls. Replace ls with sensible defaults; keep `command ls` for
# scripts that pipe its output.
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --group-directories-first'
    alias ll='eza -lah --group-directories-first --git'
    alias la='eza -a --group-directories-first'
    alias tree='eza --tree'
fi

# opencode - short alias; function wrapper in fns/opencode.sh handles tmux labels.
alias oc='opencode'
