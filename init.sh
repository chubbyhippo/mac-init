#!/usr/bin/env sh

line_exists() {
  if [ "$#" -ne 2 ]; then
    printf '%s\n' 'Usage: line_exists "TEXT" FILE' >&2
    return 2
  fi

  [ -f "$2" ] && grep -F -x -q -e "$1" "$2"
}

append() {
  if [ "$#" -ne 2 ]; then
    printf '%s\n' 'Usage: append "TEXT" FILE' >&2
    return 2
  fi

  line=$1
  file=$2
  # Do nothing if the exact line already exists
  if line_exists "$line" "$file"; then
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
  if line_exists "$line" "$file"; then
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
defaults write NSGlobalDomain NSWindowShouldDragOnGesture YES
# move focus with tab and shift + tab
defaults write NSGlobalDomain AppleKeyboardUIMode -int "2"
# autohide dock, cmd + alt + d
defaults write com.apple.dock "autohide" -bool "true"
# remove dock autohide animation
defaults write com.apple.dock "autohide-time-modifier" -float "0"
# minimize animation effect
defaults write com.apple.dock "mineffect" -string "scale"
# show all hidden files, cmd + shift + .
defaults write com.apple.finder "AppleShowAllFiles" -bool "true"
# show path bar
defaults write com.apple.finder "ShowPathbar" -bool "true"
# keep folders on top
defaults write com.apple.finder "_FXSortFoldersFirst" -bool "true"
# open folder in new window with right click
defaults write com.apple.finder "FinderSpawnTab" -bool "false"
# set search scope to current folder
defaults write com.apple.finder "FXDefaultSearchScope" -string "SCcf"
# do not display the warning when changing the file extension
defaults write com.apple.finder "FXEnableExtensionChangeWarning" -bool "false"
# tap to click
defaults write com.apple.AppleMultitouchTrackpad "Clicking" -bool "true"
# trackpad right click with two finger tab
defaults write com.apple.AppleMultitouchTrackpad "TrackpadRightClick" -bool "true"
# trackpad three finger drag
defaults write com.apple.AppleMultitouchTrackpad "TrackpadThreeFingerDrag" -bool "true"
# Fn to change input source
defaults write com.apple.HIToolbox AppleFnUsageType -int "1"
# Use F1–F12 as standard function keys (require Fn for media/brightness)
defaults write NSGlobalDomain com.apple.keyboard.fnState -bool true
# keep space arrangement for the mission control
defaults write com.apple.dock "mru-spaces" -bool "false" 
# disable application from internet popup
defaults write com.apple.LaunchServices "LSQuarantine" -bool "false"
# Disable previous input source (id 60), ctrl + space
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 '{enabled = 0; value = { parameters = (32,49,262144); type = standard; }; }'
/usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:60:enabled false" "$HOME/Library/Preferences/com.apple.symbolichotkeys.plist"
# Disable next input source (id 61), ctrl + shift + space
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 61 '{enabled = 0; value = { parameters = (32,49,786432); type = standard; }; }'
/usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:61:enabled false" "$HOME/Library/Preferences/com.apple.symbolichotkeys.plist"
# reload
killall Dock

# backup .zshrc
cp "$HOME/.zshrc" "$HOME/.zshrc-backup-$(date +%Y%m%d%H%M%S)"

# brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
curl https://raw.githubusercontent.com/chubbyhippo/homebrew-brew/refs/heads/main/Brewfile -o "$HOME/.Brewfile"
brew bundle --global
append 'eval "$(mise activate zsh)"' "$HOME/.zshrc"
