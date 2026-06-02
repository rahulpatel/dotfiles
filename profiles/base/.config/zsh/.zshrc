# $ZDOTDIR/.zshrc - interactive shell config.
#
# Tool-specific init lives in conf.d/<name>.sh. The list below is the
# single source of truth for what loads and in what order. Order matters
# for some things (e.g. zsh-syntax-highlighting must be last), so we use
# an explicit list rather than globbing.

ZSH_CONF_D=(
    vi-mode               # `bindkey -v` + escape-key fixes; load before plugins
    history               # HISTFILE + history-related setopts
    options               # AUTO_CD, EXTENDED_GLOB, etc.
    completion            # compinit + zstyle UX
    mise                  # runtime version manager
    starship              # prompt
    tools                 # fzf, zoxide, eza aliases
    plugins               # zsh-autosuggestions
    syntax-highlighting   # MUST be last
)

for _f in "${ZSH_CONF_D[@]}"; do
    _path="$ZDOTDIR/conf.d/$_f.sh"
    [ -r "$_path" ] && source "$_path"
done
unset _f _path
