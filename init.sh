#!/usr/bin/env sh

check=0
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

	if [ "$check" -eq 1 ]; then
		printf 'would append to %s: %s\n' "$file" "$line"
		return 0
	fi

	backup_once "$file"
	printf '%s\n' "$line" >>"$file"
	printf 'appended to %s: %s\n' "$file" "$line"
}

fetch() {
	if [ "$#" -ne 2 ]; then
		printf '%s\n' 'Usage: fetch URL FILE' >&2
		return 2
	fi

	url=$1
	file=$2
	tmp="${file}.$$.__tmp"

	if [ "$check" -eq 1 ]; then
		printf 'would refresh %s from %s\n' "$file" "$url"
		return 0
	fi

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

run() {
	if [ "$#" -eq 0 ]; then
		printf '%s\n' 'Usage: run COMMAND [ARG...]' >&2
		return 2
	fi

	if [ "$check" -eq 1 ]; then
		printf 'would run: %s\n' "$*"
		return 0
	fi

	"$@"
}

set_default() {
	# the per-machine scope that the trackpad checkboxes read
	scope=""
	if [ "${1:-}" = "-currentHost" ]; then
		scope=$1
		shift
	fi

	if [ "$#" -lt 3 ]; then
		printf '%s\n' 'Usage: set_default [-currentHost] DOMAIN KEY [-type] VALUE' >&2
		return 2
	fi

	domain=$1
	key=$2
	shift 2

	label="$domain $key"
	if [ -n "$scope" ]; then
		label="$scope $label"
	fi

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

	# $scope is empty or exactly -currentHost, so it stays unquoted
	if [ "$(defaults $scope read "$domain" "$key" 2>/dev/null)" = "$want" ]; then
		return 0
	fi

	changed=$((changed + 1))
	case $domain in
	com.apple.dock) reload_dock=1 ;;
	com.apple.finder) reload_finder=1 ;;
	esac

	if [ "$check" -eq 1 ]; then
		printf 'would set %s\n' "$label"
		return 0
	fi

	defaults $scope write "$domain" "$key" "$@"

	# a protected domain fails SILENTLY without Full Disk Access, so confirm
	# the write by reading it back
	if [ "$(defaults $scope read "$domain" "$key" 2>/dev/null)" != "$want" ]; then
		printf 'warn: %s did not take, give the terminal Full Disk Access\n' \
			"$label" >&2
		changed=$((changed - 1))
		return 1
	fi

	printf 'set %s\n' "$label"
}

hotkey_disabled() {
	if [ "$#" -ne 1 ]; then
		printf '%s\n' 'Usage: hotkey_disabled SLOT' >&2
		return 2
	fi

	defaults read com.apple.symbolichotkeys AppleSymbolicHotKeys 2>/dev/null |
		tr -d ' \n' | grep -E -q "[;{]$1=\{enabled=0;"
}

kanata_deployed() {
	[ -f /etc/kanata/mac.kbd ] &&
		[ -f /Library/LaunchDaemons/dev.kanata.kanata.plist ]
}

main() {
	case ${1:-} in
	--check) check=1 ;;
	-h | --help)
		printf 'usage: init.sh [--check]\n'
		printf '  --check   report what would change, write nothing\n'
		return 0
		;;
	"") ;;
	*)
		printf 'unknown option: %s\n' "$1" >&2
		return 2
		;;
	esac

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
	# tap to click, the trackpad driver, a magic trackpad, and the checkbox
	set_default com.apple.AppleMultitouchTrackpad Clicking -bool true
	set_default com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
	set_default -currentHost NSGlobalDomain com.apple.mouse.tapBehavior -int 1
	set_default NSGlobalDomain com.apple.mouse.tapBehavior -int 1
	# trackpad right click with two finger tab
	set_default com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true
	# trackpad three finger drag
	set_default com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
	# Fn to change input source
	set_default com.apple.HIToolbox AppleFnUsageType -int 1
	# repeat held keys instead of showing the accent popup
	set_default NSGlobalDomain ApplePressAndHoldEnabled -bool false
	# fast key repeat, the fastest the sliders offer
	set_default NSGlobalDomain InitialKeyRepeat -int 15
	set_default NSGlobalDomain KeyRepeat -int 2
	# keep space arrangement for the mission control
	set_default com.apple.dock mru-spaces -bool false
	# disable application from internet popup
	set_default com.apple.LaunchServices LSQuarantine -bool false
	# disable ctrl+space
	if ! hotkey_disabled 60; then
		changed=$((changed + 1))
		if [ "$check" -eq 1 ]; then
			printf 'would set com.apple.symbolichotkeys 60\n'
		else
			defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 "<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>32</integer><integer>49</integer><integer>262144</integer></array><key>type</key><string>standard</string></dict></dict>"
			printf 'set com.apple.symbolichotkeys 60\n'
		fi
	fi

	# reload only what actually changed
	if [ "$reload_dock" -eq 1 ]; then
		run killall Dock
	fi
	if [ "$reload_finder" -eq 1 ]; then
		run killall Finder
	fi

	if [ "$check" -eq 1 ]; then
		printf 'defaults: %s would change\n' "$changed"
	else
		printf 'defaults: %s changed\n' "$changed"
	fi

	# brew
	if ! command -v brew >/dev/null 2>&1; then
		if [ "$check" -eq 1 ]; then
			printf 'would install Homebrew\n'
		else
			echo "Homebrew not found. Installing..."
			NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		fi
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
			run brew bundle --global
			run brew cleanup --prune=all
		fi
	else
		printf 'warn: brew is not on PATH — skipped the Brewfile bundle\n' >&2
	fi

	# kanata, not in the Brewfile
	if ! command -v kanata >/dev/null 2>&1; then
		if command -v brew >/dev/null 2>&1; then
			run brew install kanata
		else
			printf 'warn: brew is not on PATH — skipped installing kanata\n' >&2
		fi
	fi

	# the keyboard config, its driver and its daemons, as root. The first run
	# stops for a one-time driver approval in System Settings, the next finishes
	if command -v kanata >/dev/null 2>&1 && ! kanata_deployed; then
		if [ "$check" -eq 1 ]; then
			printf 'would install the keyboard config, driver and daemons as root\n'
		else
			installer=$(mktemp /tmp/kanata-install.XXXXXX)
			if curl -fsSL https://raw.githubusercontent.com/chubbyhippo/kanata-settings/refs/heads/main/mac/install.sh -o "$installer"; then
				if ! sudo sh "$installer"; then
					printf 'warn: the keyboard install failed, rerun it after granting sudo\n' >&2
				fi
			else
				printf 'warn: could not download the keyboard installer\n' >&2
			fi
			rm -f "$installer"
		fi
	fi

	append 'eval "$(mise activate zsh)"' "$HOME/.zshrc"
	fetch https://raw.githubusercontent.com/chubbyhippo/aerospace/main/.aerospace.toml "$HOME/.aerospace.toml"
	append 'eval "$(starship init zsh)"' "$HOME/.zshrc"
	append 'export PATH="$PATH:/Applications/IntelliJ IDEA CE.app/Contents/MacOS"' "$HOME/.zshrc"
}

# test.sh sources this file for the helpers alone
if [ -z "${MAC_INIT_LIB:-}" ]; then
	main "$@"
fi
