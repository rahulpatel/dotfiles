# history - sane defaults; XDG-located history file.
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
[ -d "${HISTFILE:h}" ] || mkdir -p "${HISTFILE:h}"

HISTSIZE=100000      # commands kept in memory per session
SAVEHIST=100000      # commands persisted to HISTFILE

setopt INC_APPEND_HISTORY    # write each command as it runs (not on exit)
setopt SHARE_HISTORY         # share history live across open shells
setopt HIST_IGNORE_DUPS      # drop consecutive duplicates
setopt HIST_IGNORE_SPACE     # commands starting with a space aren't saved
setopt HIST_REDUCE_BLANKS    # normalise whitespace before saving
setopt HIST_VERIFY           # !! and friends expand before execution
