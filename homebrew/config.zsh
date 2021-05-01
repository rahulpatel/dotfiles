export PATH="/usr/local/sbin:$PATH"

# Add homebrew autocomplete to FPATH, compinit called in zsh/zshrc.symlink
FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH
