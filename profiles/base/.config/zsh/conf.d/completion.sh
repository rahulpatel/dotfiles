# completion - turn on zsh's built-in completion system with sensible UX.
autoload -Uz compinit
# -C skips the security check on the cache, much faster startup. Trade-off:
# new completions added today won't be picked up until tomorrow. Acceptable.
compinit -C

zstyle ':completion:*' menu select                           # arrow-key menu
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'    # case-insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"      # colourise matches
zstyle ':completion:*:descriptions' format '%F{yellow}%d%f'  # section headers
