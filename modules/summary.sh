#!/usr/bin/env bash
# modules/summary.sh - print a completion message. No interactive prompts.

finish() {
    log ""
    log "Done."
    log "Active profile: $PROFILE"
    log "Some changes (shell, certain defaults) may require a logout to take effect."
}
