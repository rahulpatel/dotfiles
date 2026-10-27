function code
    if test -z $argv
        set argv ""
    end

    set -l query (string replace '/' '' $argv)

    set -l selected (
        begin
            find (dirname "$DOTFILES_DIR") -mindepth 1 -maxdepth 1 -type d -name (basename "$DOTFILES_DIR")'*'
            find "$HOME/.config" -maxdepth 0 -type d

            if test -d "$CODE_DIR"
                find "$CODE_DIR" -mindepth 1 -maxdepth 1 -type d
            end
        end | fzf --select-1 --query "$query"
    )

    if test -z $selected
        return 0
    end

    if not command -q rex
        echo "code: rex is not on PATH; open Rex first" >&2
        return 1
    end

    set -l name (basename $selected)
    set -l session_id (
        rex ls --json \
            | jq -r --arg label "$name" '.sessions[] | select(.label == $label) | .session_id' \
            | head -n 1
    )

    if test -z "$session_id"
        set session_id (rex new $name -c $selected --json | jq -r '.session_id')
    end

    rex do session.select session_id=$session_id
end
