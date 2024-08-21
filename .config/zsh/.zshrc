bindkey -s '^f' 'code\n'

# Exports
export XDG_CONFIG_HOME="$HOME/.config"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
export DOTFILES_DIR="$HOME/.dotfiles"
export PROJECTS_DIR="$HOME/Developer"

# Antidote
source "$ZDOTDIR/antidote/antidote.zsh"
antidote load "$ZDOTDIR/plugins.txt"

# Library configurations
source "$XDG_CONFIG_HOME/homebrew/config.sh"
source "$XDG_CONFIG_HOME/asdf/config.sh"
source "$XDG_CONFIG_HOME/golang/config.sh"
source "$XDG_CONFIG_HOME/android/config.sh"

# Find a faster way to do this
# for file in $(find "$DOTFILES_DIR/.config" -name "config.sh" ! -path "*homebrew*"); do
# echo $file
#     source $file
# done
