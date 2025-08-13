#!/usr/bin/env sh

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

# brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
curl https://raw.githubusercontent.com/chubbyhippo/homebrew-brew/refs/heads/main/Brewfile -o "$HOME/.Brewfile"
brew bundle --global
