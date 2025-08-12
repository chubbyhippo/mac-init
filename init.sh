#!/usr/bin/env sh

configure_zsh() {
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
}

install_brew() {
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	curl https://raw.githubusercontent.com/chubbyhippo/homebrew-brew/refs/heads/main/Brewfile -o "$HOME/Brewfile"
	brew bundle --global
	export PATH="/usr/local/opt/curl/bin:$PATH"
	export PATH="/usr/local/opt/libpq/bin:$PATH"
 	append_to_zshrc "export PATH=\"$HOME/.bin:$PATH\""	
}

mac_setup() {
	defaults write -g NSWindowShouldDragOnGesture YES
}

mac_setup
pre_setup
configure_zsh
install_brew

