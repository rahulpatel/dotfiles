set fish_greeting

set -gx EDITOR nvim

set -gx MANPAGER 'nvim +Man!'

fish_add_path $HOME/.local/bin

fish_config theme choose catppuccin-mocha
# >>> mise:activate >>> managed by mise — do not edit between markers
if status is-interactive
    mise activate fish | source
else
    mise activate fish --shims | source
end
# <<< mise:activate <<<
