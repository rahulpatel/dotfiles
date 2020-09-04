# Add custom functions with autocomplete
FPATH=$DOTFILES_ROOT/functions:$FPATH
autoload -U $DOTFILES_ROOT/functions/*(:t)

# Use vim for ssh sessions
if [[ -n $SSH_CONNECTION ]]; then
 export EDITOR='vim'
else
 export EDITOR='code'
fi

# Better history (https://coderwall.com/p/jpj_6q/zsh-better-history-searching-with-arrow-keys)
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search # Up
bindkey "^[[B" down-line-or-beginning-search # Down
