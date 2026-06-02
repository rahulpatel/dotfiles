# homebrew - put brew on PATH and export HOMEBREW_PREFIX for downstream use.
# Apple Silicon: /opt/homebrew; Intel: /usr/local. Tries both.
if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi
