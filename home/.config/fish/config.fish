# disable welcome message
set fish_greeting

# Set Editor to neovim
set -gx EDITOR nvim

# Set neovim as the program to open manpages
set -gx MANPAGER 'nvim +Man!'

fish_add_path ~/.dotfiles.v3

fish_config theme choose catppuccin-mocha
