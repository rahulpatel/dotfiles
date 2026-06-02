# options - misc interactive-shell behaviour.
setopt AUTO_CD              # `dirname` alone cd's into it
setopt AUTO_PUSHD           # cd pushes the old dir onto the stack
setopt PUSHD_IGNORE_DUPS    # don't duplicate dirs on the stack
setopt PUSHD_SILENT         # don't print the stack after each cd
setopt EXTENDED_GLOB        # **/, ^pattern, etc.
setopt GLOB_DOTS            # globs match dotfiles without explicit .
setopt INTERACTIVE_COMMENTS # allow # comments in interactive shells
setopt NO_BEEP              # no terminal bell
