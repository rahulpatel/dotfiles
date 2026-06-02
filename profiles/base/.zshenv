# ~/.zshenv stub - relocates the rest of zsh's config under XDG and hands off
# to $ZDOTDIR/.zshenv for everything else.
#
# This file must live at $HOME/.zshenv: zsh reads it (after /etc/zshenv)
# unconditionally on every invocation, before $ZDOTDIR is known.

export ZDOTDIR="$HOME/.config/zsh"
[ -r "$ZDOTDIR/.zshenv" ] && source "$ZDOTDIR/.zshenv"
