function fish_prompt
    set -l cwd (prompt_pwd)

    set_color $theme_foreground
    echo -n "$cwd "

    # Show git branch and dirty state
    set -l git_branch (command git symbolic-ref HEAD 2> /dev/null | sed -e 's|^refs/heads/||')
    set -l git_dirty (command git status -s --ignore-submodules=dirty 2> /dev/null)

    if test -n "$git_branch"
        echo -n "("
        if test -n "$git_dirty"
            set_color $theme_red
            echo -n "$git_branch"
        else
            set_color $theme_green
            echo -n "$git_branch"
        end
        set_color $theme_foreground
        echo -n ") "
    end

    set_color $theme_foreground
    echo -n '→ '
end
