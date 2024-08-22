function code
    if test -z $argv
        set argv ""
    end

    set selected (find $HOME $CODE_DIR -mindepth 1 -maxdepth 1 -type d | fzf --select-1 --query $argv)

    if test -z $selected
        return 0
    end

    set name (basename $selected | tr . _)

    if not test -z (pgrep tmux) || not tmux has-session -t $name 2>/dev/null
        tmux new-session -ds $name -c $selected
    end

    if test -z $TMUX
        tmux attach-session -t $name
    else
        tmux switch-client -t $name
    end
end
