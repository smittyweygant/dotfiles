#!/usr/bin/env bash
# Seeds the OBS WebSocket password into the login Keychain under service
# `whisperx-obs-ws-password`. The whisperx recorder resolves this at runtime
# via `security find-generic-password`. Prompts once; no-ops on re-runs.

set -euo pipefail

SERVICE="whisperx-obs-ws-password"
ACCOUNT="$(whoami)"

if security find-generic-password -a "$ACCOUNT" -s "$SERVICE" -w >/dev/null 2>&1; then
    echo "Keychain item '$SERVICE' already set - skipping"
    exit 0
fi

echo "Enter the OBS WebSocket password (Settings → WebSocket Server → Show Connect Info):"
read -rs OBS_PW
if [[ -z "$OBS_PW" ]]; then
    echo "Empty password - aborting" >&2
    exit 1
fi

security add-generic-password -a "$ACCOUNT" -s "$SERVICE" -w "$OBS_PW"
echo "Keychain item '$SERVICE' added for account '$ACCOUNT'"
