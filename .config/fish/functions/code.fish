function code
    if test -z $argv
        set argv ""
    end

    set selected (find $HOME $CODE_DIR $CODE_DIR/work -mindepth 1 -maxdepth 1 -type d | fzf --select-1 --query $argv)

    if test -z $selected
        return 0
    end

    set name (basename $selected | tr . _)

    if test -z $TMUX
        tmux attach-session -t $name 2>/dev/null || tmux new-session -s $name -c $selected
    else
        tmux switch-client -t $name 2>/dev/null || tmux new-session -s $name -c $selected
    end
end
