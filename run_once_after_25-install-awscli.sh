#!/usr/bin/env bash
# AWS CLI v2 isn't in the Brewfile: AWS explicitly recommends its own
# installer over Homebrew's community-maintained `awscli` formula, which
# lags behind official releases. The install script downloads, verifies,
# and installs for the current user (no sudo) to $HOME/.local/share/aws-cli
# with a symlink in $HOME/.local/bin, which .zshrc already puts on PATH.
# Idempotent: skips if `aws` is already on PATH.
set -euo pipefail

if command -v aws >/dev/null 2>&1; then
  echo "AWS CLI already installed: $(aws --version)"
  exit 0
fi

curl -fsSL https://awscli.amazonaws.com/v2/install.sh | bash
