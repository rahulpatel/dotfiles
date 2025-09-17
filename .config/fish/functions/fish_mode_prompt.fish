function fish_mode_prompt
    if test "$fish_key_bindings" = fish_vi_key_bindings -o "$fish_key_bindings" = fish_hybrid_key_bindings
        switch $fish_bind_mode
            case default
                # normal
                set_color $theme_blue
                echo -n n
            case insert
                set_color $theme_green
                echo -n i
            case visual
                set_color $theme_magenta
                echo -n v
            case replace_one
                set_color $theme_red
                echo -n r
        end
        set_color normal
        echo -n " "
    end
end
