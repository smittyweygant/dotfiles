#!/usr/bin/env bash
# SDKMAN manages the JDK that Akka's nexus builds on. Its .sdkmanrc names the exact
# build (`java=25.0.4-tem`), so SDKMAN is the one manager that reproduces it without
# translation. Homebrew's temurin cask tracks the newest JDK, which nexus's enforcer
# rejects.
#
# The installer is told not to edit ~/.zshrc (chezmoi owns it). SDKMAN records the first
# JDK as its own default, but nothing puts it on PATH, so shells keep the Homebrew JDK.
# Activate the pinned one in a project with:
#   source ~/.sdkman/bin/sdkman-init.sh && sdk env
# Idempotent: skips whatever is already installed.
set -euo pipefail

readonly JDK_ID="25.0.4-tem"
export SDKMAN_DIR="$HOME/.sdkman"

if [ ! -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]; then
  curl -fsSL "https://get.sdkman.io?rcupdate=false" | bash
fi

# sdkman-init.sh reads unset variables, which `set -u` rejects.
set +u
# shellcheck disable=SC1091
source "$SDKMAN_DIR/bin/sdkman-init.sh"

if [ ! -d "$SDKMAN_DIR/candidates/java/$JDK_ID" ]; then
  # "n" answers the "set as default?" prompt on later installs.
  echo n | sdk install java "$JDK_ID"
fi
echo "JDK $JDK_ID: $SDKMAN_DIR/candidates/java/$JDK_ID"
