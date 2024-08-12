export ZDOTDIR="$HOME/.config/zsh"

if [[ ! -d "$ZDOTDIR/antidote" ]]; then
    git clone --depth=1 https://github.com/mattmc3/antidote.git "$ZDOTDIR/antidote"
fi

source "$ZDOTDIR/antidote/antidote.zsh"

# Set the root name of the plugins files (.txt and .zsh) antidote will use.
ZSH_PLUGINS="$ZDOTDIR/zsh-plugins"

# Lazy-load antidote from its functions directory.
fpath=("$ZDOTDIR/antidote/functions" $fpath)
autoload -Uz antidote

# Generate a new static file whenever .zsh_plugins.txt is updated.
if [[ ! "$ZSH_PLUGINS.zsh" -nt "$ZSH_PLUGINS.txt" ]]; then
  antidote bundle <"$ZSH_PLUGINS.txt" >|"$ZSH_PLUGINS.zsh"
fi

# Source your static plugins file.
source "$ZSH_PLUGINS.zsh"



# export PROJECTS_ROOT="$HOME/Developer"
# export DOTFILES_ROOT="$HOME/.dotfiles"
#
# if [[ -f "$HOME/.localrc" ]]; then
#   source "$HOME/.localrc"
# fi
#
# source "$DOTFILES_ROOT/homebrew/config.sh"
#
# for file in $(bash "$DOTFILES_ROOT/lib/find.sh" "config.sh"); do
#   source "$file"
# done
#
# for file in $(bash "$DOTFILES_ROOT/lib/find.sh" "completion.sh"); do
#   source "$file"
# done
#
# for file in $(bash "$DOTFILES_ROOT/lib/find.sh" "alias.zsh"); do
#   source "$file"
# done
#
# # bind ctrl+f to auto run function/c
# bindkey -s ^f "c\n"
#
# # oh-my-zsh config
# zstyle ':omz:update' mode auto
#
# # Load the oh-my-zsh library.
# antigen use oh-my-zsh
#
# # Bundles from the default repo (robbyrussell's oh-my-zsh).
# antigen bundle git
# antigen bundle command-not-found
#
# # Other bundles
# antigen bundle zsh-users/zsh-autosuggestions
# antigen bundle zsh-users/zsh-syntax-highlighting
#
# # Load the theme.
# antigen theme refined
# # antigen theme robbyrussell
# # antigen theme vercel/zsh-theme
# # antigen theme gozilla
# # antigen bundle reobin/typewritten@main
# # antigen theme spaceship-prompt/spaceship-prompt
#
# # Tell Antigen that you're done.
# antigen apply
