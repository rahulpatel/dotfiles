# Machine specific env vars
source "$HOME/.profile"

# Exports
export XDG_CONFIG_HOME="$HOME/.config"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
export DOTFILES_DIR="$HOME/.dotfiles"
export PROJECTS_DIR="$HOME/Developer"

# Library configurations
source "$XDG_CONFIG_HOME/homebrew/config.sh"

for file in $(find "$DOTFILES_DIR/.config" -name "config.sh" ! -path "*homebrew*"); do
    source $file
done

#---------------------------------------------------------------------------
# Prompt
#---------------------------------------------------------------------------
autoload -U colors && colors

RED="%{$fg[red]%}"
GREY="%{$fg[grey]%}"
GREEN="%{$fg[green]%}"
RESET="%{$reset_color%}"

function parse_git_branch() {
    [ -d .git ] || return 1
    BRANCH=$(git symbolic-ref HEAD 2> /dev/null | sed 's#\(.*\)\/\([^\/]*\)$#\2#')
    DIRTY=$(git status --porcelain --untracked-files=no 2>/dev/null | tail -n1)

    if [[ -n "$DIRTY" ]]; then
        echo "${RED}(${BRANCH})${RESET}"
    else
        echo "${GREEN}(${BRANCH})${RESET}"
    fi
}

PROMPT="%~ $(parse_git_branch) → "

