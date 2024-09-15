function fish_mode_prompt
    if [ $fish_key_bindings = fish_vi_key_bindings ]
        or test "$fish_key_bindings" = "fish_hybrid_key_bindings"
        switch $fish_bind_mode
            case default
                set_color 8caaee
                echo -n "n"
            case insert
                set_color a6d189
                echo -n "i"
            case visual
                set_color ca9ee6
                echo -n "v"
            case replace_one
                set_color e78284
                echo -n "r"
        end
        set_color normal
        echo -n " "
    end
end

