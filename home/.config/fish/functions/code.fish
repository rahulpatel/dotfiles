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

    set -l name (basename $selected)
    set -l server_running (herdr status server --json 2>/dev/null | jq -r '.running')

    # Start the headless server first so a restored session cannot ignore the
    # selected project when the client attaches.
    if test "$server_running" != true
        command nohup herdr server >/dev/null 2>&1 </dev/null &
        disown $last_pid

        for attempt in (seq 1 50)
            set server_running (herdr status server --json 2>/dev/null | jq -r '.running')
            test "$server_running" = true; and break
            sleep 0.1
        end

        if test "$server_running" != true
            echo "code: failed to start the Herdr server" >&2
            return 1
        end
    end

    set -l workspace_id (
        herdr workspace list \
            | jq -r --arg label "$name" '.result.workspaces[] | select(.label == $label) | .workspace_id' \
            | head -n 1
    )

    if test -n "$workspace_id"
        herdr workspace focus $workspace_id >/dev/null
    else
        herdr workspace create --cwd $selected --label $name --focus >/dev/null
    end

    if not set -q HERDR_ENV
        command herdr
    end
end
