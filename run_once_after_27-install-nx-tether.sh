#!/usr/bin/env bash
# Nikon NX Tether has no Homebrew cask, and Nikon's download page hides the link behind
# an "accept" click. The link itself is a plain archive URL that needs no click, so this
# fetches it directly, checks it against a pinned hash, and runs the notarized pkg.
#
# To upgrade: take the macOS link from
#   https://downloadcenter.nikonimglib.com/en/download/sw/278.html
# follow its redirect to the archive URL, and update URL and SHA256 below.
# Idempotent: skips when the app is already installed. Prompts for sudo.
set -euo pipefail

readonly URL="https://download.nikonimglib.com/archive8/ozMoo00230jJ07BDAjh68yvlGr01/S-NXTETH-020601MF-ALLIN-ALL___.dmg"
readonly SHA256="c0d567f154e014a0307cb4b0e9f7b316709e775c7af0222e7fe995bc0e605de0"
readonly APP="/Applications/Nikon Software/NXTether/NXTether.app"

if [ -d "$APP" ]; then
  echo "NX Tether: already installed"
  exit 0
fi

work="$(mktemp -d)"
mount="$work/mnt"
mkdir "$mount"
cleanup() {
  hdiutil detach "$mount" -quiet 2>/dev/null || true
  rm -rf "$work"
}
trap cleanup EXIT

curl -fsSL -o "$work/nx-tether.dmg" "$URL"
echo "$SHA256  $work/nx-tether.dmg" | shasum -a 256 -c - >/dev/null

hdiutil attach "$work/nx-tether.dmg" -nobrowse -readonly -quiet -mountpoint "$mount"
sudo installer -pkg "$mount/Installer/NikonInstaller.pkg" -target /
echo "NX Tether: installed at $APP"
