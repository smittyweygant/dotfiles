#!/usr/bin/env bash
# Lets Touch ID satisfy sudo prompts. macOS reads /etc/pam.d/sudo_local, which survives
# OS updates (unlike edits to /etc/pam.d/sudo). chezmoi can't manage a file outside
# $HOME, so this script writes it. Needs the admin password once; Touch ID thereafter.
#
# pam_reattach (Homebrew) must come before pam_tid so Touch ID works inside tmux. On a
# first run it isn't installed yet, so its line is left out and a later run adds it.
# Idempotent: rewrites the file only when its content differs from what's wanted.
set -euo pipefail

readonly PAM_FILE="/etc/pam.d/sudo_local"
readonly REATTACH="/opt/homebrew/lib/pam/pam_reattach.so"

content="# sudo_local: local config which survives system updates"$'\n'
if [ -e "$REATTACH" ]; then
  content+="auth       optional       $REATTACH"$'\n'
fi
content+="auth       sufficient     pam_tid.so"

if [ "$(cat "$PAM_FILE" 2>/dev/null)" = "$content" ]; then
  echo "Touch ID for sudo: already configured"
  exit 0
fi

printf '%s\n' "$content" | sudo tee "$PAM_FILE" >/dev/null
echo "Touch ID for sudo: configured in $PAM_FILE"
