#!/usr/bin/env bash
# Records this machine's AWS Identity Center details by prompting for them
# (see dot_local/bin/executable_aws-sso-setup). The answers are specific to
# your AWS organization, so they are never in this repo. Skips when not run
# from a terminal; run `aws-sso-setup` by hand later.
set -euo pipefail

if [ -f "$HOME/.config/aws-sso/env" ]; then
  echo "AWS SSO details already recorded."
  exit 0
fi

if [ ! -t 0 ]; then
  echo "Not a terminal; run aws-sso-setup later to configure AWS SSO."
  exit 0
fi

"$HOME/.local/bin/aws-sso-setup"
