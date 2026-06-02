# mise - polyglot runtime version manager.
# Activates mise's shell integration so version switching works in this shell.
if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate zsh)"
fi
