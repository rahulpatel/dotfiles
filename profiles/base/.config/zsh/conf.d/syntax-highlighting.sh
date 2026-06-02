# syntax-highlighting - MUST be the last conf.d file sourced. It wraps every
# ZLE widget that exists at load time; widgets added after won't be coloured.
if [ -n "${HOMEBREW_PREFIX:-}" ] && \
   [ -r "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
    ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
    source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
