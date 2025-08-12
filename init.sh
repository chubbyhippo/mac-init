#!/usr/bin/env sh

# ctrl + cmd and click to drag from anywhere
defaults write -g NSWindowShouldDragOnGesture YES

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
curl https://raw.githubusercontent.com/chubbyhippo/homebrew-brew/refs/heads/main/Brewfile -o "$HOME/Brewfile"
brew bundle --global
