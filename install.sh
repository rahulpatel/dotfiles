#!/usr/bin/env bash

function update-macos() {
  echo "Updating macos"
  sudo softwareupdate -i -a
}

function modify-macos() {
  echo "Modifing macos"
  source ./macos.sh
}

function install-command-line-tools() {
  echo "Installing command line tools"
  xcode-select --install
}

function install-homebrew() {
  echo "Installing homebrew"
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  brew update
}

function install-tools-and-apps() {
  echo "Installing tools and applications"
  brew bundle
  brew cleanup
}

function install-oh-my-zsh() {
  echo "Installing oh my zsh"
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
}

function symlink-dotfiles() {
  echo "Symlinking dotfiles"
  local DOTFILES_SOURCE_DIR="./dotfiles/*"
  local DOTFILES_DEST_DIR="${HOME}"
  ln -si "${DOTFILES_SOURCE_DIR}" "${DOTFILES_DEST_DIR}"
}

function install-atom-plugins() {
  echo "Installing atom plugins"
  apm install editorconfig file-icons genesis-ui highlight-selected language-babel linter linter-eslint nord-atom-syntax prettier-atom
}

function set-github-user() {
  echo "Setting github identitiy"
  read -p 'Name: ' name
  git config --global user.name "$name"
  read -p 'Email: ' email
  git config --global user.email "$email"
}

echo "Bootstrapping your mac..."

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until `.macos` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

for func in "update-macos" \
            "modify-macos" \
            "install-command-line-tools" \
            "install-homebrew" \
            "install-tools-and-apps" \
            "install-oh-my-zsh" \
            "symlink-dotfiles" \
            "install-atom-plugins" \
            "set-github-user"; do
  echo "========================================================================"
  "$func"
  echo "========================================================================"
  echo ""
done

echo "Done! Restarting..."

osascript -e 'tell app "loginwindow" to «event aevtrrst»'
