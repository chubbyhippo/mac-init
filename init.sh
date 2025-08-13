#!/usr/bin/env sh

append() {
  if [ "$#" -ne 2 ]; then
    printf '%s\n' 'Usage: append "TEXT" FILE' >&2
    return 2
  fi

  line=$1
  file=$2
  # Do nothing if the exact line already exists
  if [ -f "$file" ] && grep -F -x -q -e "$line" "$file"; then
    return 0
  fi

  printf '%s\n' "$line" >> "$file"
}

prepend() {
  if [ "$#" -ne 2 ]; then
    printf '%s\n' 'Usage: prepend "TEXT" FILE' >&2
    return 2
  fi

  line=$1
  file=$2

  # Do nothing if the exact line already exists
  if [ -f "$file" ] && grep -F -x -q -e "$line" "$file"; then
    return 0
  fi

  tmp="${file}.$$.__tmp"

  if [ -f "$file" ]; then
    { printf '%s\n' "$line"; cat "$file"; } > "$tmp" || return 1
  else
    printf '%s\n' "$line" > "$tmp" || return 1
  fi

  mv "$tmp" "$file"
}

# reduce motion System Preferences -> Privacy -> Full Disk Access
defaults write com.apple.universalaccess "reduceMotion" -bool "true"
# ctrl + cmd and click to drag from anywhere
defaults write -g NSWindowShouldDragOnGesture YES
# autohide dock, cmd + alt + d
defaults write com.apple.dock "autohide" -bool "true" && killall Dock
# remove dock autohide animation
defaults write com.apple.dock "autohide-time-modifier" -float "0" && killall Dock
# minimize animation effect
defaults write com.apple.dock "mineffect" -string "scale" && killall Dock
# show all hidden files, cmd + shift + .
defaults write com.apple.finder "AppleShowAllFiles" -bool "true" && killall Finder
# show path bar
defaults write com.apple.finder "ShowPathbar" -bool "true" && killall Finder
# keep folders on top
defaults write com.apple.finder "_FXSortFoldersFirst" -bool "true" && killall Finder
# open folder in new window with right click
defaults write com.apple.finder "FinderSpawnTab" -bool "false" && killall Finder
# set search scope to current folder
defaults write com.apple.finder "FXDefaultSearchScope" -string "SCcf" && killall Finder
# do not display the warning when changing the file extension
defaults write com.apple.finder "FXEnableExtensionChangeWarning" -bool "false" && killall Finder
# trackpad three finger drag
defaults write com.apple.AppleMultitouchTrackpad "TrackpadThreeFingerDrag" -bool "true"
# Fn to change input source
defaults write com.apple.HIToolbox AppleFnUsageType -int "1"

# backup .zshrc
cp "$HOME/.zshrc" "$HOME/.zshrc-backup-$(date +%Y%m%d%H%M%S)"

# brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
curl https://raw.githubusercontent.com/chubbyhippo/homebrew-brew/refs/heads/main/Brewfile -o "$HOME/.Brewfile"
brew bundle --global
append 'eval "$(mise activate zsh)"' "$HOME/.zshrc"
