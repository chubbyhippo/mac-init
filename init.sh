#!/usr/bin/env sh

changed=0
reload_dock=0
reload_finder=0
backed_up=""

line_exists() {
	if [ "$#" -ne 2 ]; then
		printf '%s\n' 'Usage: line_exists "TEXT" FILE' >&2
		return 2
	fi

	# ignore indentation and a leading `export` so a hand-edited variant of a
	# managed line still counts as present
	needle=$(printf '%s\n' "$1" | sed 's/^[[:space:]]*//; s/^export //')

	[ -f "$2" ] && sed 's/^[[:space:]]*//; s/^export //' "$2" |
		grep -F -x -q -e "$needle"
}

backup_once() {
	if [ "$#" -ne 1 ]; then
		printf '%s\n' 'Usage: backup_once FILE' >&2
		return 2
	fi

	target=$1
	# at most one backup per file per run, and only when a change is coming
	case " $backed_up " in
	*" $target "*) return 0 ;;
	esac

	[ -f "$target" ] || return 0

	cp "$target" "$target-backup-$(date +%Y%m%d%H%M%S)" || return 1
	backed_up="$backed_up $target"
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

	backup_once "$file"
	printf '%s\n' "$line" >>"$file"
	printf 'appended to %s: %s\n' "$file" "$line"
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

	backup_once "$file"
	tmp="${file}.$$.__tmp"

	if [ -f "$file" ]; then
		{
			printf '%s\n' "$line"
			cat "$file"
		} >"$tmp" || return 1
	else
		printf '%s\n' "$line" >"$tmp" || return 1
	fi

	mv "$tmp" "$file"
	printf 'prepended to %s: %s\n' "$file" "$line"
}

fetch() {
	if [ "$#" -ne 2 ]; then
		printf '%s\n' 'Usage: fetch URL FILE' >&2
		return 2
	fi

	url=$1
	file=$2
	tmp="${file}.$$.__tmp"

	# -f so an HTTP error fails instead of writing the error page into FILE
	if ! curl -fsSL "$url" -o "$tmp"; then
		rm -f "$tmp"
		printf 'warn: could not download %s — %s left unchanged\n' "$url" "$file" >&2
		return 1
	fi

	# leave FILE untouched when the download is byte-identical
	if cmp -s "$tmp" "$file"; then
		rm -f "$tmp"
		return 0
	fi

	mv "$tmp" "$file"
	printf 'updated %s\n' "$file"
}

set_default() {
	if [ "$#" -lt 3 ]; then
		printf '%s\n' 'Usage: set_default DOMAIN KEY [-type] VALUE' >&2
		return 2
	fi

	domain=$1
	key=$2
	shift 2

	# what `defaults read` prints back for this write form: -bool reads as
	# 1 or 0, an untyped value is stored verbatim as a string
	case $1 in
	-bool)
		case $2 in
		true | TRUE | yes | YES | 1) want=1 ;;
		*) want=0 ;;
		esac
		;;
	-*) want=$2 ;;
	*) want=$1 ;;
	esac

	if [ "$(defaults read "$domain" "$key" 2>/dev/null)" = "$want" ]; then
		return 0
	fi

	defaults write "$domain" "$key" "$@"

	# a protected domain fails SILENTLY without Full Disk Access, so confirm
	# the write by reading it back
	if [ "$(defaults read "$domain" "$key" 2>/dev/null)" != "$want" ]; then
		printf 'warn: %s %s did not take, give the terminal Full Disk Access\n' \
			"$domain" "$key" >&2
		return 1
	fi

	changed=$((changed + 1))
	case $domain in
	com.apple.dock) reload_dock=1 ;;
	com.apple.finder) reload_finder=1 ;;
	esac
	printf 'set %s %s\n' "$domain" "$key"
}

hotkey_disabled() {
	if [ "$#" -ne 1 ]; then
		printf '%s\n' 'Usage: hotkey_disabled SLOT' >&2
		return 2
	fi

	defaults read com.apple.symbolichotkeys AppleSymbolicHotKeys 2>/dev/null |
		tr -d ' \n' | grep -E -q "[;{]$1=\{enabled=0;"
}

# reduce motion System Preferences -> Privacy -> Full Disk Access
set_default com.apple.universalaccess reduceMotion -bool true
# ctrl + cmd and click to drag from anywhere
set_default NSGlobalDomain NSWindowShouldDragOnGesture YES
# move focus with tab and shift + tab
set_default NSGlobalDomain AppleKeyboardUIMode -int 2
# autohide dock, cmd + alt + d
set_default com.apple.dock autohide -bool true
# remove dock autohide animation
set_default com.apple.dock autohide-time-modifier -float 0
# minimize animation effect
set_default com.apple.dock mineffect -string scale
# show all hidden files, cmd + shift + .
set_default com.apple.finder AppleShowAllFiles -bool true
# show path bar
set_default com.apple.finder ShowPathbar -bool true
# keep folders on top
set_default com.apple.finder _FXSortFoldersFirst -bool true
# open folder in new window with right click
set_default com.apple.finder FinderSpawnTab -bool false
# set search scope to current folder
set_default com.apple.finder FXDefaultSearchScope -string SCcf
# do not display the warning when changing the file extension
set_default com.apple.finder FXEnableExtensionChangeWarning -bool false
# tap to click
set_default com.apple.AppleMultitouchTrackpad Clicking -bool true
# trackpad right click with two finger tab
set_default com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true
# trackpad three finger drag
set_default com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
# Fn to change input source
set_default com.apple.HIToolbox AppleFnUsageType -int 1
# Use F1–F12 as standard function keys (require Fn for media/brightness)
set_default NSGlobalDomain com.apple.keyboard.fnState -bool true
# repeat held keys instead of showing the accent popup
set_default NSGlobalDomain ApplePressAndHoldEnabled -bool false
# keep space arrangement for the mission control
set_default com.apple.dock mru-spaces -bool false
# disable application from internet popup
set_default com.apple.LaunchServices LSQuarantine -bool false
# disable ctrl+space
if ! hotkey_disabled 60; then
	defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 "<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>32</integer><integer>49</integer><integer>262144</integer></array><key>type</key><string>standard</string></dict></dict>"
	changed=$((changed + 1))
	printf 'set com.apple.symbolichotkeys 60\n'
fi

# reload only what actually changed
if [ "$reload_dock" -eq 1 ]; then
	killall Dock
fi
if [ "$reload_finder" -eq 1 ]; then
	killall Finder
fi

printf 'defaults: %s changed\n' "$changed"

# brew
if ! command -v brew >/dev/null 2>&1; then
	echo "Homebrew not found. Installing..."
	NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
	echo "Homebrew is already installed."
fi

# the installer only PRINTS this step, so a fresh install is not on PATH yet
if ! command -v brew >/dev/null 2>&1; then
	for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
		if [ -x "$brew_bin" ]; then
			eval "$("$brew_bin" shellenv)"
			append "eval \"\$($brew_bin shellenv)\"" "$HOME/.zprofile"
			break
		fi
	done
fi

if command -v brew >/dev/null 2>&1; then
	if fetch https://raw.githubusercontent.com/chubbyhippo/homebrew-brew/refs/heads/main/Brewfile "$HOME/.Brewfile"; then
		export HOMEBREW_NO_INSTALL_CLEANUP=1
		brew bundle --global
		brew cleanup --prune=all
	fi
else
	printf 'warn: brew is not on PATH — skipped the Brewfile bundle\n' >&2
fi

append 'eval "$(mise activate zsh)"' "$HOME/.zshrc"
fetch https://raw.githubusercontent.com/chubbyhippo/aerospace/main/.aerospace.toml "$HOME/.aerospace.toml"
append 'eval "$(starship init zsh)"' "$HOME/.zshrc"
append 'export PATH="$PATH:/Applications/IntelliJ IDEA CE.app/Contents/MacOS"' "$HOME/.zshrc"
