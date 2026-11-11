# Dotfiles (chezmoi) — rules for editing

This repo is the chezmoi source directory and it is **public**. Nothing
personal goes in it: not hosts, key file names, IP addresses, account IDs, or
org details.

## Editing managed files
- Edit the source (`chezmoi source-path`), never the live file in `$HOME`.
  A live-only edit shows up later as "has changed since chezmoi last wrote it".
- Run `chezmoi diff` before and after changing a managed file. After, it
  should show only what you meant to change.
- If `chezmoi diff` shows live content the source lacks, ask which side is
  right before choosing overwrite. Do not default to overwrite.
- Don't commit before checking `git status` and naming the files you stage.

## Where personal data lives
Gitignored or untracked files on each machine, recreated by hand:
- `~/.ssh/config.local` — every SSH `Host` entry, including `github.com` and
  `github-akka` and their `IdentityFile` key names.
  `private_dot_ssh/config` may hold only `Host *` blocks and must keep
  `Include config.local` as its first directive.
- `~/.gitconfig.local` — this machine's git identity.
- `~/.config/aws-sso/env` — AWS Identity Center details, written by
  `aws-sso-setup`.
- `~/.aws/config` — seeded once by `create_private_config`; chezmoi never
  overwrites it.

When a task needs a new personal value, add or extend a `.local` file and read
it from a script. Do not template it into a tracked file.

## Enforcement
`init/git-hooks/pre-commit` rejects a commit that puts a `Host` entry other
than `Host *` into `private_dot_ssh/config`.
`run_once_after_41-enable-git-hooks.sh` turns the hook on for each clone.
