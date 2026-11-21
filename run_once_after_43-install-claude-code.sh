#!/usr/bin/env bash
# Linux only; the Mac gets Claude Code from the Brewfile. Anthropic's native
# installer puts it in ~/.local/bin. Runs after claude-config (40): the
# installer writes into ~/.claude, and claude-config only symlinks ~/.claude to
# ~/.claude-personal while that path does not yet exist as a real directory.
# Idempotent: skips if already installed.
set -euo pipefail

if [ -x "$HOME/.local/bin/claude" ]; then
  echo "Claude Code already installed: $("$HOME/.local/bin/claude" --version)"
  exit 0
fi

curl -fsSL https://claude.ai/install.sh | bash
