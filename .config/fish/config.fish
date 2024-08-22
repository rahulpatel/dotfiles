# disable welcome message
set fish_greeting ""

# vi key bingings
set -g fish_key_bindings fish_vi_key_bindings
bind -M insert \cc kill-whole-line repaint

# exports
set -Ux XDG_CONFIG_HOME $HOME/.config
set -Ux DOTFILES_DIR $HOME/.dotfiles
set -Ux CODE_DIR $HOME/Developer

# configs
source $HOME/.config/homebrew/config.sh
source $HOME/.config/asdf/config.fish
source $HOME/.config/android/config.fish
source $HOME/.config/golang/config.fish

