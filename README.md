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
- AWS uses 1Password's CLI shell plugin, not a static `~/.aws/credentials` file — see [AWS credentials](#aws-credentials) below.

### SSH keys

All private keys live in the **Development** vault in 1Password — none are stored in `~/.ssh` or this repo. The 1Password SSH agent serves them transparently:

- `dot_ssh/config.tmpl` sets `IdentityAgent` to 1Password's socket (`~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`) under the catch-all `Host *` block. Per-host `IdentityFile` lines point at `.pub` files only — these just pin *which* key to offer for a given host; the agent supplies the actual private material.
- `dot_config/1Password/ssh/agent.toml` scopes the agent to the Development vault (`vault = "Development"`). Creating a custom `agent.toml` overrides 1Password's default vault behavior, so every key that should be available over SSH needs to live in that vault — dropping a new key into a different vault silently won't show up in `ssh-add -l` until moved.
- `dot_ssh/.gitignore` is a repo-only allowlist (`config.tmpl` and `*.pub` only) so this directory can never accidentally pick up a real private key, even if something is copied in carelessly later. It's not deployed to `$HOME` itself — chezmoi skips literal dotfiles in the source tree.
- **Personal infra hostnames/IPs are templated, not hardcoded** — this repo is public, so real values (home LAN IPs, EC2 hostnames, Tailscale tailnet ID) live only in the local, untracked `~/.config/chezmoi/chezmoi.toml` under `[data.hosts]`, referenced in the template as `{{ .hosts.rpi_ip }}` etc. The two EC2 hosts use short aliases (`aws-ec2-1`/`aws-ec2-2`) instead of their real public hostnames as the `Host` match itself, since that would otherwise put the real value in the repo unavoidably.

**New machine**: after signing into the 1Password app (step 1 above), seed `~/.config/chezmoi/chezmoi.toml` with your `[data.hosts]` values (see the template's `{{ .hosts.* }}` references for which keys are needed) *before* running `chezmoi apply` — otherwise those fields render empty. Then `dot_ssh/config` and `agent.toml` land automatically. The one manual step chezmoi can't do: open each SSH Key item in 1Password (or drag the key file onto the 1Password window if a key isn't in the vault yet) so it's available to drag/import — the keys themselves live in your 1Password account and sync there, not through this repo.

### AWS credentials

The `smittoid` IAM user's access key lives in a 1Password "AWS Access Key" item in the Development vault, used via `op`'s AWS CLI shell plugin rather than a static `~/.aws/credentials` file:

- `private_dot_aws/private_config` → `~/.aws/config` (just the default region — no secrets, `private_` prefix keeps it `0600`).
- `~/.config/op/plugins.sh` is generated by `op plugin init aws` (not tracked here — it's local, regenerated per machine) and aliases `aws` to a function that fetches credentials from 1Password with a Touch ID prompt per use.
- `dot_zshrc` sources it (guarded with an existence check) **after** oh-my-zsh loads, so the 1Password-wrapped `aws` function overrides oh-my-zsh's bundled `aws` plugin rather than the other way around — get this ordering wrong and `aws` silently falls back to the (now-deleted) static credentials file.

**New machine**: after `chezmoi apply` and signing into 1Password, run `op plugin init aws` once, choose "Import" and paste in the access key, save it to the Development vault. A fresh terminal will then pick up the `aws` alias automatically.

**Note**: this is still a long-lived IAM access key, just no longer sitting in plaintext on disk — 1Password's biometric gate is the security improvement, not short-lived credentials. AWS CLI v2 also supports true temporary credentials via IAM Identity Center (SSO) if that's ever worth the bigger setup lift (Console-side permission sets, user assignment) — not pursued yet.

## Thanks to…

This repo started as a fork of [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles) — see that project for the full list of original credits and inspirations.
