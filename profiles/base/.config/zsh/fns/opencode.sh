# opencode - set tmux process label while opencode is running.

opencode() {
    emulate -L zsh

    if [[ -n "$TMUX" ]]; then
        tmux set-option -p -q @process_name opencode
        command opencode "$@"
        local status=$?
        tmux set-option -p -q -u @process_name
        return $status
    fi

    command opencode "$@"
}
