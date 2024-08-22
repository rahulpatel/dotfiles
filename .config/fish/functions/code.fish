function code
    set selected (find $HOME $CODE_DIR -mindepth 1 -maxdepth 1 -type d | fzf --query $argv --select-1)

    if test -z $selected
        exit
    end

    set name (basename $selected | tr . _)

    if test -z $TMUX
        if tmux has-session -t=$name 2>/dev/null
            tmux attach-session -t $name
        else if test (count (pgrep tmux)) -ne 0
            tmux new-session -ds $name -c $selected
        end
    else
        if tmux has-session -t=$name 2>/dev/null
            tmux switch-client -t $name
        else
            tmux new-session -ds $name -c $selected
        end
    end
end
