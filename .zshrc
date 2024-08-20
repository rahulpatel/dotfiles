export ZDOTDIR="$HOME/.config/zsh"

source "$ZDOTDIR/antidote/antidote.zsh"
source "$HOME/.config/homebrew/config.sh"
source "$HOME/.config/pkgx/config.sh"
source "$HOME/.config/golang/config.sh"
source "$HOME/.config/android/config.sh"

antidote load "$ZDOTDIR/plugins.txt"
