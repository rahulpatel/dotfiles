if command -q eza
    alias ls 'eza --group-directories-first'
    alias ll 'eza -lah --group-directories-first --git'
    alias la 'eza -a --group-directories-first'
    alias tree 'eza --tree'
end
