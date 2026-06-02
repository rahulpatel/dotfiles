# $ZDOTDIR/.zshenv - per-user env, sourced for every zsh invocation
# (interactive, non-interactive, login, scripts). Keep it cheap.
#
# Tool-specific env init lives in env.d/<name>.sh. Listed explicitly so the
# order is visible.

ZSH_ENV_D=(
    homebrew
)

for _f in "${ZSH_ENV_D[@]}"; do
    _path="$ZDOTDIR/env.d/$_f.sh"
    [ -r "$_path" ] && source "$_path"
done
unset _f _path
