#!/usr/bin/env sh
# Tests init.sh's helpers. Writes only inside a temp dir and a throwaway
# defaults domain, both removed on exit.

MAC_INIT_LIB=1
export MAC_INIT_LIB

here=$(cd "$(dirname "$0")" && pwd)
. "$here/init.sh"

passed=0
failed=0
scratch_domain=com.macinit.test
work=$(mktemp -d /tmp/mac-init-test.XXXXXX)

cleanup() {
	defaults delete "$scratch_domain" 2>/dev/null
	defaults -currentHost delete "$scratch_domain" 2>/dev/null
	rm -rf "$work"
}
trap cleanup EXIT

ok() {
	passed=$((passed + 1))
	printf 'ok   %s\n' "$1"
}

no() {
	failed=$((failed + 1))
	printf 'FAIL %s\n' "$1"
}

is() {
	if [ "$2" = "$3" ]; then
		ok "$1"
	else
		no "$1 (want [$3], got [$2])"
	fi
}

# --- line_exists ------------------------------------------------------------

zshrc="$work/zshrc"
managed='export PATH="$PATH:/Applications/IntelliJ IDEA CE.app/Contents/MacOS"'
printf '%s\n' "$managed" >"$zshrc"
printf '\teval "$(mise activate zsh)"\n' >>"$zshrc"

line_exists "$managed" "$zshrc"
is "line_exists matches the same line" "$?" 0
line_exists 'PATH="$PATH:/Applications/IntelliJ IDEA CE.app/Contents/MacOS"' "$zshrc"
is "line_exists ignores a leading export" "$?" 0
line_exists 'eval "$(mise activate zsh)"' "$zshrc"
is "line_exists ignores indentation" "$?" 0
line_exists 'eval "$(starship init zsh)"' "$zshrc"
is "line_exists misses an absent line" "$?" 1
line_exists onearg 2>/dev/null
is "line_exists rejects bad arity" "$?" 2

# --- append and backup_once -------------------------------------------------

cp "$zshrc" "$work/zshrc.before"
append 'eval "$(starship init zsh)"' "$zshrc" >/dev/null
append 'eval "$(starship init zsh)"' "$zshrc" >/dev/null
append "$managed" "$zshrc" >/dev/null
is "append adds a line once" "$(wc -l <"$zshrc" | tr -d ' ')" 3

backups=$(find "$work" -name 'zshrc-backup-*' | wc -l | tr -d ' ')
is "append backs up once per run" "$backups" 1
cmp -s "$work/zshrc.before" "$(find "$work" -name 'zshrc-backup-*')"
is "the backup holds the pre-change content" "$?" 0

backup_once "$work/absent"
is "backup_once skips a missing file" "$(find "$work" -name 'absent-backup-*' | wc -l | tr -d ' ')" 0

fresh="$work/created"
append 'a line' "$fresh" >/dev/null
is "append creates a missing file" "$(cat "$fresh")" "a line"

# --- fetch ------------------------------------------------------------------

printf 'payload\n' >"$work/source"
fetch "file://$work/source" "$work/dest" >/dev/null
is "fetch writes the file" "$(cat "$work/dest")" "payload"

before=$(ls -i "$work/dest" | awk '{print $1}')
fetch "file://$work/source" "$work/dest" >/dev/null
is "fetch leaves identical content alone" "$(ls -i "$work/dest" | awk '{print $1}')" "$before"

printf 'precious\n' >"$work/keep"
fetch "file://$work/does-not-exist" "$work/keep" 2>/dev/null
is "fetch reports a failed download" "$?" 1
is "a failed fetch preserves the target" "$(cat "$work/keep")" "precious"
is "a failed fetch leaves no temp file" "$(find "$work" -name '*.__tmp' | wc -l | tr -d ' ')" 0

# --- set_default ------------------------------------------------------------

changed=0
set_default "$scratch_domain" flag -bool true >/dev/null
is "set_default writes a new key" "$changed" 1
set_default "$scratch_domain" flag -bool true >/dev/null
is "set_default skips a key already set" "$changed" 1

for form in "-bool false" "-int 2" "-float 0" "-string SCcf" "YES"; do
	key=$(printf 'k%s' "$form" | tr -cd 'a-zA-Z0-9')
	changed=0
	# shellcheck disable=SC2086
	set_default "$scratch_domain" "$key" $form >/dev/null
	first=$changed
	# shellcheck disable=SC2086
	set_default "$scratch_domain" "$key" $form >/dev/null
	is "set_default round-trips [$form]" "$first:$changed" "1:1"
done

changed=0
set_default -currentHost "$scratch_domain" hostkey -int 1 >/dev/null
first=$changed
set_default -currentHost "$scratch_domain" hostkey -int 1 >/dev/null
is "set_default handles -currentHost" "$first:$changed" "1:1"

changed=0
set_default "$scratch_domain" coerced -int 1.5 >/dev/null 2>&1
is "set_default detects a write that did not take" "$?" 1
is "a failed write is not counted" "$changed" 0

set_default "$scratch_domain" 2>/dev/null
is "set_default rejects bad arity" "$?" 2

reload_dock=0
reload_finder=0
set_default com.apple.dock macInitTestProbe -bool true >/dev/null
set_default com.apple.finder macInitTestProbe -bool true >/dev/null
is "a dock key asks for a Dock restart" "$reload_dock" 1
is "a finder key asks for a Finder restart" "$reload_finder" 1
defaults delete com.apple.dock macInitTestProbe 2>/dev/null
defaults delete com.apple.finder macInitTestProbe 2>/dev/null

# --- check mode -------------------------------------------------------------

check=1
changed=0
touched="$work/untouched"
printf 'original\n' >"$touched"
append 'new line' "$touched" >/dev/null
is "check mode does not append" "$(cat "$touched")" "original"
fetch "file://$work/source" "$touched" >/dev/null
is "check mode does not fetch" "$(cat "$touched")" "original"
set_default "$scratch_domain" checkonly -bool true >/dev/null
is "check mode counts without writing" "$changed" 1
is "check mode wrote no key" "$(defaults read "$scratch_domain" checkonly >/dev/null 2>&1 && echo wrote || echo clean)" "clean"
is "run reports instead of running" "$(run touch "$work/should-not-exist")" "would run: touch $work/should-not-exist"
is "run created nothing" "$(find "$work" -name 'should-not-exist' | wc -l | tr -d ' ')" 0
check=0

# --- predicates and arity ---------------------------------------------------

hotkey_disabled 2>/dev/null
is "hotkey_disabled rejects bad arity" "$?" 2
hotkey_disabled 60
case $? in
0 | 1) ok "hotkey_disabled answers cleanly (slot 60 on this host)" ;;
*) no "hotkey_disabled returned an unexpected status" ;;
esac
kanata_deployed
case $? in
0 | 1) ok "kanata_deployed answers cleanly (this host)" ;;
*) no "kanata_deployed returned an unexpected status" ;;
esac
run 2>/dev/null
is "run rejects an empty command" "$?" 2

# --- init.sh --check end to end ---------------------------------------------

# MAC_INIT_LIB is exported for the sourcing above, so it has to be dropped
# here or these child runs would skip main and prove nothing
out=$(env -u MAC_INIT_LIB sh "$here/init.sh" --check 2>&1)
is "--check exits clean" "$?" 0
case $out in
*"would change"*) ok "--check reports a summary" ;;
*) no "--check printed no summary" ;;
esac
case $out in
*"
set "* | "set "*) no "--check performed a write" ;;
*) ok "--check performed no writes" ;;
esac

env -u MAC_INIT_LIB sh "$here/init.sh" --bogus >/dev/null 2>&1
is "an unknown option exits 2" "$?" 2
env -u MAC_INIT_LIB sh "$here/init.sh" --help >/dev/null 2>&1
is "--help exits clean" "$?" 0

# --- result -----------------------------------------------------------------

printf '\n%s passed, %s failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
