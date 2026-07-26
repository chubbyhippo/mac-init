# mac-init

Takes a fresh Mac to a working setup: system `defaults`, Homebrew and its
global Brewfile, the kanata keyboard config, and the zsh hooks for `mise`
and `starship`.

## Before you run it

Give the terminal **Full Disk Access** (System Settings -> Privacy &
Security -> Full Disk Access). One protected setting (reduce motion) fails
silently without it — the script warns when a write does not take.

## Run it

```sh
curl -fsSL https://raw.githubusercontent.com/chubbyhippo/mac-init/main/init.sh | /usr/bin/env sh
```

Safe to re-run: every step checks the current state first and only writes
when something differs, so a second run changes nothing and says
`defaults: 0 changed`.

To see what a run would change without touching anything:

```sh
curl -fsSL https://raw.githubusercontent.com/chubbyhippo/mac-init/main/init.sh | /usr/bin/env sh -s -- --check
```

## What it does

**System settings** — 25 `defaults` keys: reduce motion, Dock autohide with
no animation, Finder (hidden files, path bar, folders first, current-folder
search, no extension warning), trackpad (tap to click, two-finger right
click, three-finger drag), keyboard (F-key focus navigation, Globe switches
input source, fast key repeat, no accent popup on held keys), no Gatekeeper
download prompt, and **Ctrl+Space freed** so it can be a mark key in an
editor instead of an input-source switch. Dock and Finder are restarted only
if one of their own keys changed.

**Homebrew** — installed if missing, then `~/.Brewfile` is fetched and
applied with `brew bundle --global`. Adds `eval "$(brew shellenv)"` to
`~/.zprofile` when Homebrew is not yet on `PATH`, which the Homebrew
installer only prints as a manual step.

**Keyboard** — installs the `kanata` formula and deploys its config, driver
and launch daemons. **This part uses `sudo` and installs a system driver**,
so expect a password prompt. Apple requires one manual approval:
System Settings -> General -> Login Items & Extensions -> Driver Extensions
-> enable Karabiner-DriverKit-VirtualHIDDevice. The first run stops there;
run the script again afterwards and it finishes. Skipped entirely once the
config and its daemon are in place.

**zsh** — appends the `mise`, `starship` and IntelliJ IDEA CE `PATH` lines to
`~/.zshrc`, and fetches `~/.aerospace.toml`. Any file it is about to change
is backed up first, once per run, as `<file>-backup-<timestamp>`.

## Development

```sh
shfmt -l -w .
./test.sh
```

`test.sh` covers the helpers and the `--check` path. It writes only inside a
temp dir and a throwaway `defaults` domain, both removed on exit.

Reading a setting back, e.g. to check the Ctrl+Space entry:

```sh
defaults read com.apple.symbolichotkeys AppleSymbolicHotKeys
```

## refs

https://macos-defaults.com/
https://gist.github.com/bennlee/0f5bc8dc15a53b2cc1c81cd92363bf18
