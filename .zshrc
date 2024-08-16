source "$HOME/.config/zsh/config.sh"
source "$HOME/.config/homebrew/config.sh"

for file in $(find .config -name "config.sh" ! -path "*homebrew*" ! -path "*zsh*"); do
  source "$file"
done
