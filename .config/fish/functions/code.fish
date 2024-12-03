function code
    if test -z $argv
        set argv ""
    end

    set selected (find $HOME $CODE_DIR -mindepth 1 -maxdepth 1 -type d | fzf --select-1 --query $argv)

    if test -z $selected
        return 0
    end

    set name (basename $selected | tr . _)

    tmux new-session -As $name -c $selected
end
