#!/usr/bin/env bash
# Clones (or updates) the personal Claude Code/Codex config repo and installs
# it into ~/.claude-personal. HTTPS clone, matching the zsh-framework script's
# idiom — install.sh itself is idempotent, safe to re-run.
set -euo pipefail

REPO_DIR="$HOME/development/claude-config"

if [ -d "$REPO_DIR/.git" ]; then
  git -C "$REPO_DIR" pull --ff-only
else
  mkdir -p "$HOME/development"
  git clone https://github.com/smittyweygant/claude-config.git "$REPO_DIR"
fi

bash "$REPO_DIR/install.sh"
