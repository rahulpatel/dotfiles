# starship - cross-shell prompt.
# Config: ~/.config/starship.toml
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi
