# homebrew - put brew on PATH and export HOMEBREW_PREFIX for downstream use.

export HOMEBREW_NO_ENV_HINTS=1

if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
