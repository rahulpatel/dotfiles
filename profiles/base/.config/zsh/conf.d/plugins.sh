# plugins - zsh-autosuggestions. Sourced after compinit, before syntax
# highlighting. Suggestion appears in grey; accept with right-arrow.
if [ -n "${HOMEBREW_PREFIX:-}" ] && \
   [ -r "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
    source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi
