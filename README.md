# Smitty's dotfiles

Personal macOS toolchain and configuration, managed with [chezmoi](https://www.chezmoi.io/). Originally forked from [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles); restructured to be reproducible on a fresh machine.

## What's here

- Shell config (zsh + oh-my-zsh + Powerlevel10k), editor config (vim), git config, and assorted CLI tool dotfiles — all managed as `dot_*` files that chezmoi renders into `$HOME`.
- `run_once_before_10-macos-defaults.sh` — macOS system preference tweaks (`defaults write` commands), runs once on a fresh machine.
- `run_once_before_05-create-vim-dirs.sh` — creates vim's backup/swap/undo directories.
- `Brewfile` + `run_onchange_install-packages.sh.tmpl` — Homebrew formulae/casks, reinstalled automatically whenever the Brewfile changes.
- `MASfile` + `run_onchange_install-mas-apps.sh.tmpl` — Mac App Store apps via [`mas`](https://github.com/mas-cli/mas).
- `APPLICATIONS.md` — apps installed outside Homebrew/the App Store (direct download, MDM) that can't be scripted; a manual-reinstall checklist.
- `init/` — app-specific settings (Sublime Text, iTerm2/Terminal color profiles, Spectacle) that need manual import; not chezmoi-managed.

Secrets (SSH keys, AWS credentials, API tokens) are **not** stored here — see [Secrets](#secrets) below.

## New machine setup

1. Install [1Password](https://1password.com/) and the 1Password CLI, sign in, and enable the SSH agent + CLI integration (Settings → Developer). This is the one manual gate — everything else here depends on `op` being signed in.
2. Install Homebrew: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
3. Install chezmoi and apply this repo:
   ```bash
   brew install chezmoi
   chezmoi init --apply git@github.com:smittyweygant/dotfiles.git
   ```
   This clones the repo, runs the `run_once_` setup scripts (macOS defaults, vim dirs), renders all `dot_*` files into `$HOME`, and runs the `run_onchange_` scripts (Homebrew bundle, MAS apps).
4. Work through `APPLICATIONS.md` for anything that can't be scripted.

## Day-to-day usage

```bash
chezmoi edit ~/.zshrc      # opens the source file for editing
chezmoi diff               # preview what would change
chezmoi apply -v           # apply changes to $HOME
```

To pick up a package you just installed by hand into the tracked Brewfile:

```bash
brew bundle dump --file=Brewfile --describe --force
```

then review the diff before committing.

## Secrets

- SSH keys live in the **1Password SSH agent**, not `~/.ssh`.
- AWS credentials use 1Password's AWS CLI shell plugin, not a static `~/.aws/credentials`.
- Shell env secrets (API keys, tokens) are pulled lazily in `dot_zshrc.tmpl` via `op read 'op://...'` at shell startup — never rendered into the file itself and never committed.

## Thanks to…

This repo started as a fork of [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles) — see that project for the full list of original credits and inspirations.
