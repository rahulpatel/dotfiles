eval "$(/opt/homebrew/bin/brew shellenv)"

# Add homebrew autocomplete to FPATH, compinit called in zsh/zshrc.symlink
FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH
