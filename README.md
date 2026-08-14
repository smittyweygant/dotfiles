# Smitty's dotfiles

Personal macOS toolchain and configuration, managed with [chezmoi](https://www.chezmoi.io/). Originally forked from [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles); restructured to be reproducible on a fresh machine.

## What's here

- Shell config (zsh + oh-my-zsh + Powerlevel10k), editor config (vim), git config, and assorted CLI tool dotfiles — all managed as `dot_*` files that chezmoi renders into `$HOME`.
- `dot_ssh/config` + `dot_config/1Password/ssh/agent.toml` — SSH client config and 1Password SSH agent scoping. No private keys are ever tracked here; see [SSH keys](#ssh-keys) below.
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

- Shell env secrets (API keys, tokens) are pulled lazily in `dot_zshrc` via `op read 'op://...'` at shell startup — never rendered into the file itself and never committed.
- **AWS credentials are currently still a static `~/.aws/credentials` file — not yet migrated to 1Password.** This is a known gap, not a completed step; treat it the same as any other unrotated static credential until it's addressed.

### SSH keys

All private keys live in the **Development** vault in 1Password — none are stored in `~/.ssh` or this repo. The 1Password SSH agent serves them transparently:

- `dot_ssh/config` sets `IdentityAgent` to 1Password's socket (`~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`) under the catch-all `Host *` block. Per-host `IdentityFile` lines point at `.pub` files only — these just pin *which* key to offer for a given host; the agent supplies the actual private material.
- `dot_config/1Password/ssh/agent.toml` scopes the agent to the Development vault (`vault = "Development"`). Creating a custom `agent.toml` overrides 1Password's default vault behavior, so every key that should be available over SSH needs to live in that vault — dropping a new key into a different vault silently won't show up in `ssh-add -l` until moved.
- `dot_ssh/.gitignore` is a repo-only allowlist (`config` and `*.pub` only) so this directory can never accidentally pick up a real private key, even if something is copied in carelessly later. It's not deployed to `$HOME` itself — chezmoi skips literal dotfiles in the source tree.

**New machine**: after signing into the 1Password app (step 1 above) and running `chezmoi apply`, `dot_ssh/config` and `agent.toml` land automatically. The one manual step chezmoi can't do: open each SSH Key item in 1Password (or drag the key file onto the 1Password window if a key isn't in the vault yet) so it's available to drag/import — the keys themselves live in your 1Password account and sync there, not through this repo.

## Thanks to…

This repo started as a fork of [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles) — see that project for the full list of original credits and inspirations.
