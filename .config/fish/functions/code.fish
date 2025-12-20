function code
    if test -z $argv
        set argv ""
    end

    set -l query (string replace '/' '' $argv)

    set -l selected (
        begin
            find "$HOME" -mindepth 1 -maxdepth 1 -type d
            find "$CODE_DIR" -mindepth 1 -maxdepth 2 -type d
        end | fzf --select-1 --query "$query"
    )

    if test -z $selected
        return 0
    end

    set name (basename $selected | tr . _)

    if not tmux has-session -t $name 2>/dev/null
        tmux new-session -d -s $name -c $selected

        tmux send-keys -t $name:1 'nvim .' C-m
        tmux new-window -t $name:2 -c $selected

        tmux select-window -t $name:1
    end

    if test -z $TMUX
        tmux attach-session -t $name
    else
        tmux switch-client -t $name
    end
end
