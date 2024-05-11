#!/usr/bin/env bash

append_to_zshrc() {
 local text="$1" zshrc
 local skip_new_line="${2:-0}"

  if [ -w "$HOME/.zshrc.local" ]; then
    zshrc="$HOME/.zshrc.local"
  else
    zshrc="$HOME/.zshrc"
  fi
  
  if ! grep -Fqs "$text" "$zshrc"; then
    if [ "$skip_new_line" -eq 1 ]; then
      printf "%s\\n" "$text" >> "$zshrc"
    else
      printf "\\n%s\\n" "$text" >> "$zshrc"
    fi
  fi

}

prepend_to_zshrc() {
  local text="$1" zshrc

  if [ -w "$HOME/.zshrc.local" ]; then
    zshrc="$HOME/.zshrc.local"
  else
    zshrc="$HOME/.zshrc"
  fi

  printf "%s\n\n%s" "$text" "$(cat "$zshrc")" > "$zshrc"
}
pre_setup() {
  if [ ! -d "$HOME/.bin/" ]; then
    mkdir "$HOME/.bin"
  fi

  if [ ! -f "$HOME/.zshrc" ]; then
    touch "$HOME/.zshrc"
  fi

  if [ ! -f "$HOME/.Brewfile" ]; then
    touch "$HOME/.Brewfile"
  fi

  append_to_zshrc "export PATH=\"$HOME/.bin:$PATH\""

  # Determine Homebrew prefix
  ARCH="$(uname -m)"
  if [ "$ARCH" = "arm64" ]; then
    HOMEBREW_PREFIX="/opt/homebrew"
  else
    HOMEBREW_PREFIX="/usr/local"
  fi
}

prepend_to_zshrc "test"
echo "test"