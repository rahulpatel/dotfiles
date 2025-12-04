function fish_user_key_bindings
    for mode in default insert visual normal
        bind -M $mode ctrl-f 'code' repaint
    end
end
