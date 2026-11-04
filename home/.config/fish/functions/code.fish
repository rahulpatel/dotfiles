function code
    set -l query (string join ' ' -- $argv)

    set -l selected (
        begin
            printf '%s\n' "$DOTFILES_DIR"
            printf '%s\n' "$HOME/.config"

            if test -d "$CODE_DIR"
                find "$CODE_DIR" -mindepth 1 -maxdepth 1 -type d
            end
        end | fzf --select-1 --query "$query"
    )

    if test -z "$selected"
        return 0
    end

    if not command -q rex
        echo "code: rex is not on PATH; open Rex first" >&2
        return 1
    end

    set -l name (basename "$selected")
    set -l label "$name [$selected]"
    set -l sessions (rex ls --json)
    or return 1

    set -l session_id (printf '%s\n' "$sessions" | jq -r --arg label "$label" '[.sessions[] | select(.label == $label)][0].session_id // empty')
    or return 1

    if test -z "$session_id"
        set -l created (rex new "$label" -c "$selected" --json)
        or return 1
        set session_id (printf '%s\n' "$created" | jq -er '.session_id | select(type == "string" and length > 0 and . != "null")')
        or return 1
    end

    rex do session.select "session_id=$session_id"
end
