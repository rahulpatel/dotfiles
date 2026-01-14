# disable welcome message
set fish_greeting ""

# vi key bingings
set -g fish_key_bindings fish_vi_key_bindings
bind ctrl-c cancel-commandline repaint

# machine specific vars
if test -f $HOME/.profile.fish
    source $HOME/.profile.fish
end

# exports
set -Ux XDG_CONFIG_HOME $HOME/.config
set -Ux DOTFILES_DIR $HOME/.dotfiles
set -Ux CODE_DIR $HOME/Developer

# configs
source $HOME/.config/homebrew/config.sh
source $HOME/.config/android/config.fish

fish_config theme choose "Catppuccin Mocha"
starship init fish | source

# aliases
alias vim="nvim"
alias oc="opencode"
