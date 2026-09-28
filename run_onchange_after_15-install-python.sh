#!/usr/bin/env bash
set -euo pipefail

# Project .python-version files select this runtime when needed. Do not change
# pyenv's global version; projects without a local selection keep their current
# behavior.
readonly PYTHON_VERSION="3.12.8"

if ! command -v pyenv >/dev/null 2>&1; then
  echo "pyenv not found — install the Brewfile first"
  exit 1
fi

pyenv install --skip-existing "$PYTHON_VERSION"
