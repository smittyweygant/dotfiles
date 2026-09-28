#!/usr/bin/env bash
# Clones the call-analysis pipeline + private prompts repos so the WhisperX
# recorder can bootstrap on a fresh machine. Idempotent: pulls if already cloned.

set -euo pipefail

SUITE_DIR="$HOME/development/call-analysis-suite"
mkdir -p "$SUITE_DIR"

for repo in call-analysis call-analysis-prompts; do
    target="$SUITE_DIR/$repo"
    if [[ -d "$target/.git" ]]; then
        echo "[$repo] pulling latest…"
        git -C "$target" pull --ff-only
    else
        echo "[$repo] cloning…"
        git clone "git@github.com:smittyweygant/$repo.git" "$target"
    fi
done
