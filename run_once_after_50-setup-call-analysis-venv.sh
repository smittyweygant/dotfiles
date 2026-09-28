#!/usr/bin/env bash
# Bootstraps the whisperx-recorder Python venv. Uses pyenv-installed 3.12.8
# (see run_onchange_after_15-install-python.sh). WhisperX itself is installed
# separately because its PyTorch pins conflict with the requirements resolver.

set -euo pipefail

REPO_DIR="$HOME/development/call-analysis-suite/call-analysis/processing-pipeline"
VENV_DIR="$REPO_DIR/.venv"

if [[ ! -d "$REPO_DIR" ]]; then
    echo "call-analysis repo not found at $REPO_DIR - skipping venv setup" >&2
    exit 0
fi

if [[ -x "$VENV_DIR/bin/whisperx" ]]; then
    echo "whisperx venv already provisioned at $VENV_DIR"
    exit 0
fi

PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
PYTHON_BIN="$PYENV_ROOT/versions/3.12.8/bin/python3"
if [[ ! -x "$PYTHON_BIN" ]]; then
    echo "pyenv Python 3.12.8 not installed - run run_onchange_after_15 first" >&2
    exit 1
fi

"$PYTHON_BIN" -m venv "$VENV_DIR"
"$VENV_DIR/bin/pip" install --upgrade pip
"$VENV_DIR/bin/pip" install -r "$REPO_DIR/requirements.txt"
"$VENV_DIR/bin/pip" install whisperx
