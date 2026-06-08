# pi - the Pi CLI runs through node, so tmux sees `node` as the foreground
# command. While Pi is running, hint the status bar to display `pi` instead.
pi() {
    if [[ -n "${TMUX-}" ]] && command -v tmux >/dev/null 2>&1; then
        tmux set-option -p -q @process_name pi
        command pi "$@"
        local rc=$?
        tmux set-option -p -q -u @process_name
        return "$rc"
    fi

    command pi "$@"
}
