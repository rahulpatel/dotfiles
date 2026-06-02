# vi-mode - zsh's built-in vi keybindings, with the sharp edges filed off.
#
# Press Esc to enter normal mode (hjkl, w/b, dd, ciw, etc.). Press `v` in
# normal mode to open the current command line in $EDITOR.

bindkey -v

# Default Esc timeout is 400ms, which feels laggy when switching modes.
export KEYTIMEOUT=1   # 10ms

# vi mode breaks a few keys most people rely on. Restore them.
bindkey '^?' backward-delete-char    # backspace works across insert point
bindkey '^H' backward-delete-char    # ctrl-h
bindkey '^W' backward-kill-word
bindkey '^U' backward-kill-line
bindkey '^R' history-incremental-search-backward

# Esc-v: edit the current command line in $EDITOR (killer feature).
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line
