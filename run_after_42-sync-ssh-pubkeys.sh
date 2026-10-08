#!/usr/bin/env bash
# config.local (gitignored, never in this repo) references SSH keys by
# `IdentityFile ~/.ssh/<name>.pub` — a local stub so ssh asks the 1Password
# agent for that one key instead of offering every key it holds, which trips
# the server's MaxAuthTries before reaching the right one. Recreating
# config.local by hand (README) doesn't recreate those stubs, so this runs
# on every apply and backfills any that are missing from the matching
# 1Password SSH Key item in the Development vault.

set -uo pipefail

CONFIG_LOCAL="$HOME/.ssh/config.local"

if [[ ! -f "$CONFIG_LOCAL" ]]; then
    echo "ssh: ~/.ssh/config.local not found - skipping pubkey sync (see README#ssh-keys)"
    exit 0
fi

if ! command -v op >/dev/null 2>&1; then
    echo "ssh: 1Password CLI ('op') not found - skipping pubkey sync" >&2
    exit 0
fi

# Every `.pub` path referenced via IdentityFile, deduped.
mapfile -t pub_paths < <(
    grep -ioE '^\s*IdentityFile\s+\S+\.pub' "$CONFIG_LOCAL" \
        | awk '{print $2}' \
        | sort -u
)

missing_paths=()
for raw_path in "${pub_paths[@]}"; do
    path="${raw_path/#\~/$HOME}"
    [[ -f "$path" ]] || missing_paths+=("$path")
done

if [[ ${#missing_paths[@]} -eq 0 ]]; then
    exit 0
fi

echo "ssh: ${#missing_paths[@]} pubkey stub(s) missing - checking 1Password (approve any prompt in the app if it hangs)..."
items_json="$(op item list --categories "SSH Key" --vault Development --format=json 2>&1)"
if [[ $? -ne 0 ]]; then
    echo "ssh: couldn't reach 1Password ('$items_json') - skipping pubkey sync, retry next apply" >&2
    exit 0
fi

missing=0
for path in "${missing_paths[@]}"; do
    stem="$(basename "$path" .pub)"
    matches="$(python3 -c "
import json, sys
stem = sys.argv[1].lower()
items = json.loads(sys.argv[2])
print('\n'.join(i['id'] for i in items if stem in i['title'].lower()))
" "$stem" "$items_json")"
    match_count="$(grep -c . <<<"$matches" || true)"

    if [[ "$match_count" -eq 0 ]]; then
        echo "ssh: no 1Password SSH Key item matches '$stem' for $path - add/import it in the Development vault, then re-run" >&2
        missing=$((missing + 1))
        continue
    fi
    if [[ "$match_count" -gt 1 ]]; then
        echo "ssh: multiple 1Password SSH Key items match '$stem' for $path - resolve manually" >&2
        missing=$((missing + 1))
        continue
    fi

    item_id="$matches"
    pubkey="$(op item get "$item_id" --fields label=public_key 2>/dev/null)"
    if [[ -z "$pubkey" ]]; then
        echo "ssh: could not read public key for '$stem' from 1Password - skipping $path" >&2
        missing=$((missing + 1))
        continue
    fi

    mkdir -p "$(dirname "$path")"
    printf '%s\n' "$pubkey" >"$path"
    chmod 644 "$path"
    echo "ssh: wrote $path from 1Password item '$stem'"
done

if [[ "$missing" -gt 0 ]]; then
    echo "ssh: $missing pubkey stub(s) still need manual attention - see warnings above" >&2
fi

exit 0
