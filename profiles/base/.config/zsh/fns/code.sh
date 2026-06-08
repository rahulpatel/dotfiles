# code - pick/open a repo in the Television code channel.
#
# Usage:
#   code              # show all repos
#   code gatehouse    # open immediately if that query has exactly one match;
#                     # otherwise open tv with "gatehouse" pre-filled

code() {
    emulate -L zsh

    local source_cmd="$HOME/.local/bin/tv-code-source"
    local open_cmd="$HOME/.local/bin/tv-code-open"

    if (( $# == 0 )); then
        command tv code
        return
    fi

    local query="$*"
    local output
    local -a matches

    output="$(
        "$source_cmd" | awk -v q="$query" '
            BEGIN {
                n = split(tolower(q), terms, /[[:space:]]+/)
            }
            {
                line = tolower($0)
                ok = 1
                for (i = 1; i <= n; i++) {
                    if (terms[i] != "" && index(line, terms[i]) == 0) {
                        ok = 0
                        break
                    }
                }
                if (ok) print
            }
        '
    )"
    matches=(${(f)output})

    if (( ${#matches[@]} == 1 )); then
        "$open_cmd" "${matches[1]#*$'\t'}"
    else
        command tv --input "$query" code
    fi
}
