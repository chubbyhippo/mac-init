#!/usr/bin/env bash

append_to_zshrc() {
	local text="$1" zshrc
	local skip_new_line="${2:-0}"

	zshrc="$HOME/.zshrc"

	if ! grep -Fqs "$text" "$zshrc"; then
		if [ "$skip_new_line" -eq 1 ]; then
			printf "%s\\n" "$text" >>"$zshrc"
		else
			printf "\\n%s\\n" "$text" >>"$zshrc"
		fi
	fi
}

prepend_to_zshrc() {
	local text="$1" zshrc

	zshrc="$HOME/.zshrc"

	printf "%s\n\n%s" "$text" "$(cat "$zshrc")" >"$zshrc"
}

pre_setup() {
	if [ ! -f "$HOME/.zshrc" ]; then
		touch "$HOME/.zshrc"
	fi
}

configure_zsh() {
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
}

install_brew() {
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	curl https://raw.githubusercontent.com/chubbyhippo/homebrew/main/Brewfile -o "$HOME/.Brewfile"
	brew bundle --global
	export PATH="/usr/local/opt/curl/bin:$PATH"
	export PATH="/usr/local/opt/libpq/bin:$PATH"
 	append_to_zshrc "export PATH=\"$HOME/.bin:$PATH\""
}

mac_setup() {
	xcode-select --install
	defaults write -g NSWindowShouldDragOnGesture YES
	curl https://raw.githubusercontent.com/chubbyhippo/aerospace/main/.aerospace.toml -o ~/.aerospace.toml
}
pre_setup
mac_setup
install_brew
configure_zsh
echo "Finished"
