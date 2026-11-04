if test -x /opt/homebrew/bin/brew
  /opt/homebrew/bin/brew shellenv | source
else
  set -gx HOMEBREW_PREFIX /opt/homebrew
  fish_add_path -gm /opt/homebrew/bin /opt/homebrew/sbin
end
