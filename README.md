# mac-init

Takes a fresh Mac to a working setup: system `defaults`, Homebrew and its
global Brewfile, the kanata keyboard config, and the zsh hooks for `mise` and
`starship`.

## Before you run it

| Prerequisite | Where |
|---|---|
| **Full Disk Access** for the terminal | System Settings → Privacy & Security → Full Disk Access |

Without it the reduce-motion key fails silently; the script warns when a write
does not take.

## Run it

```sh
curl -fsSL https://raw.githubusercontent.com/chubbyhippo/mac-init/main/init.sh | /usr/bin/env sh
```

Dry run — prints what would change, writes nothing:

```sh
curl -fsSL https://raw.githubusercontent.com/chubbyhippo/mac-init/main/init.sh | /usr/bin/env sh -s -- --check
```

Every step checks the current state first, so a second run reports
`defaults: 0 changed`.

## What it does

| Stage | What |
|---|---|
| System settings | 25 `defaults` keys (see below); Dock and Finder restart only if one of their own keys changed |
| Homebrew | installed if missing, then `~/.Brewfile` fetched and applied with `brew bundle --global`; `eval "$(brew shellenv)"` appended to `~/.zprofile` when Homebrew is not yet on `PATH` |
| Keyboard | the `kanata` formula plus its config, driver and launch daemons — **uses `sudo`, installs a system driver**; skipped once the config and its daemon are in place |
| zsh | appends the `mise`, `starship` and IntelliJ IDEA CE `PATH` lines to `~/.zshrc`, and fetches `~/.aerospace.toml` |
| Backups | any file about to change is copied once per run to `<file>-backup-<timestamp>` |

| `defaults` group | Keys |
|---|---|
| Accessibility | reduce motion |
| Dock | autohide, no animation |
| Finder | hidden files, path bar, folders first, current-folder search, no extension warning |
| Trackpad | tap to click, two-finger right click, three-finger drag |
| Keyboard | F-key focus navigation, Globe switches input source, fast key repeat, no accent popup on held keys |
| Gatekeeper | no download prompt |
| Hotkeys | **Ctrl+Space freed** — a mark key in an editor instead of an input-source switch |

### Driver approval

| Step | Do |
|---|---|
| 1 | First run stops at the driver step |
| 2 | System Settings → General → Login Items & Extensions → Driver Extensions → enable Karabiner-DriverKit-VirtualHIDDevice |
| 3 | Re-run the script; it finishes |

## Development

```sh
shfmt -l -w .
./test.sh
```

`test.sh` covers the helpers and the `--check` path, writing only inside a temp
dir and a throwaway `defaults` domain, both removed on exit.

Read a setting back, e.g. the Ctrl+Space entry:

```sh
defaults read com.apple.symbolichotkeys AppleSymbolicHotKeys
```

## refs

https://macos-defaults.com/
https://gist.github.com/bennlee/0f5bc8dc15a53b2cc1c81cd92363bf18
