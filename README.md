# Smitty's dotfiles

Personal macOS toolchain and configuration, managed with [chezmoi](https://www.chezmoi.io/). Originally forked from [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles); restructured to be reproducible on a fresh machine.

## What's here

- Shell config (zsh + oh-my-zsh + Powerlevel10k), editor config (vim), git config, and assorted CLI tool dotfiles — all managed as `dot_*` files that chezmoi renders into `$HOME`.
- `private_dot_ssh/config` + `dot_config/private_1Password/ssh/agent.toml` — SSH client config and 1Password SSH agent scoping. No private keys are ever tracked here; see [SSH keys](#ssh-keys) below.
- `run_once_before_10-macos-defaults.sh.tmpl` — macOS system preference tweaks (`defaults write` commands), runs once on a fresh machine.
- `run_once_before_05-create-vim-dirs.sh` — creates vim's backup/swap/undo directories.
- `run_once_after_20-install-zsh-framework.sh` — clones oh-my-zsh, Powerlevel10k, and the custom zsh plugins `.zshrc` expects.
- `run_once_after_25-install-awscli.sh` — installs AWS CLI v2 via [AWS's official install script](https://awscli.amazonaws.com/v2/install.sh), not Homebrew (its community `awscli` formula lags behind official releases).
- `run_once_after_30-import-app-settings.sh.tmpl` — iTerm2 color preset and other tweaks that need the apps installed first.
- `run_onchange_after_35-install-iterm-profile.sh.tmpl` — installs `init/iterm-profile.json` as an iTerm2 Dynamic Profile (font, keybindings, cursor, window behavior — everything the `.itermcolors` preset alone doesn't cover). Re-runs when the profile JSON changes. See [iTerm2 profile](#iterm2-profile) for the export flow.
- `Brewfile` + `run_onchange_10-install-packages.sh.tmpl` — Homebrew formulae/casks, reinstalled automatically whenever the Brewfile changes.
- `MASfile` + `run_onchange_20-install-mas-apps.sh.tmpl` — Mac App Store apps via [`mas`](https://github.com/mas-cli/mas).
- `APPLICATIONS.md` — apps installed outside Homebrew/the App Store (direct download, MDM) that can't be scripted; a manual-reinstall checklist.
- `init/` — app-specific settings that get consumed by the scripts above: `Solarized Dark.itermcolors` (iTerm color preset), `Solarized Dark xterm-256color.terminal` (Terminal.app color preset — currently unused), `spectacle.json` (Spectacle keybindings — Spectacle itself is retired), and — when populated — `iterm-profile.json` (full iTerm Dynamic Profile export).

Secrets (SSH keys, AWS credentials, API tokens) are **not** stored here — see [Secrets](#secrets) below.

## New machine setup

Prerequisites: signed in to iCloud (Apple ID) and to the **App Store app** (the MAS step below can't sign in for you).

1. **Install Homebrew** (it also installs the Xcode Command Line Tools, and asks for your password):
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
   On Apple Silicon Homebrew lives in `/opt/homebrew`, which isn't on `PATH` yet in the current shell — the installer prints a `brew shellenv` line to run; typically:
   ```bash
   eval "$(/opt/homebrew/bin/brew shellenv)"
   ```
   (The chezmoi-managed `.zshrc` does this automatically once applied.)
2. **Install 1Password and its CLI, sign in, and enable both the SSH agent and CLI integration** (Settings → Developer). This is the one manual gate — everything else depends on `op` being signed in.
   ```bash
   brew install --cask 1password 1password-cli
   ```
   The **CLI integration** side needs one extra bit beyond the toggle — see [AWS credentials](#aws-credentials) for the full 3-step Full Disk Access dance. It can wait until step 6, but if you plan to use `aws` (or any `op`-wrapped tool) right after apply, it's easier to knock out here.
3. **Install chezmoi and apply this repo.** Clone over **HTTPS**, not SSH: the repo is public, and `~/.ssh/config` (which points ssh at the 1Password agent) doesn't exist until this step finishes, so an SSH clone would fail.
   ```bash
   brew install chezmoi
   chezmoi init --apply https://github.com/smittyweygant/dotfiles.git
   ```
   This clones the repo, runs the `run_once_before_` scripts (macOS defaults — prompts for sudo — and vim dirs), renders all `dot_*` files into `$HOME`, then runs the `run_onchange_` Homebrew bundle and MAS installs and the `run_once_after_` scripts (zsh framework, AWS CLI, app settings). The Homebrew bundle is long and some casks (Docker Desktop, Zoom, Microsoft Office) prompt for your password partway through.
   Afterwards, optionally switch the clone to SSH so you can push: `git -C ~/.local/share/chezmoi remote set-url origin git@github.com:smittyweygant/dotfiles.git`
4. **Per-machine files chezmoi deliberately doesn't create** (open a fresh terminal first):
   - `~/.gitconfig.local` — this machine's git identity, e.g. `[user]` / `name = …` / `email = …`. The tracked `~/.gitconfig` includes it last so it overrides the default.
   - `~/.ssh/config.local` — personal hosts; see [SSH keys](#ssh-keys).
   - `op plugin init aws` — see [AWS credentials](#aws-credentials).
5. **Finish by hand**: pick the Solarized Dark preset and Hack Nerd Font in iTerm2, sign in to the installed apps, and log out/in so the macOS defaults fully apply. Work through `APPLICATIONS.md` for anything not scripted (and its "Undecided" list).
6. **Verify**: `brew bundle check --file=$(chezmoi source-path)/Brewfile`, `chezmoi diff` (should be empty), and `ssh -T git@github.com`.

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

- `private_dot_ssh/config` sets `IdentityAgent` to 1Password's socket (`~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`) under the catch-all `Host *` block, and includes `github.com` directly (nothing sensitive there). Per-host `IdentityFile` lines point at `.pub` files only — these just pin *which* key to offer for a given host; the agent supplies the actual private material.
- `dot_config/private_1Password/ssh/agent.toml` scopes the agent to the Development vault (`vault = "Development"`). Creating a custom `agent.toml` overrides 1Password's default vault behavior, so every key that should be available over SSH needs to live in that vault — dropping a new key into a different vault silently won't show up in `ssh-add -l` until moved.
- `private_dot_ssh/.gitignore` is a repo-only allowlist (`config` and `*.pub` only) so this directory can never accidentally pick up a real private key, even if something is copied in carelessly later. It's not deployed to `$HOME` itself — chezmoi skips literal dotfiles in the source tree.
- **Personal infra (home LAN IPs, EC2 hostnames, Tailscale FQDN) lives in `~/.ssh/config.local`, gitignored and never part of this public repo at all** — not obfuscated/templated, just not tracked. `private_dot_ssh/config` pulls it in via `Include config.local` as the very **first** line in the file — OpenSSH (tested on 10.2p1/LibreSSL) silently ignores an `Include` that comes after any `Host` block, so don't reorder this.

**New machine**: after signing into the 1Password app (step 2 above) and running `chezmoi apply`, `private_dot_ssh/config` and `agent.toml` land automatically, but `~/.ssh/config.local` does not — it's deliberately never in this repo (not even in git history), so recreate it by hand from memory/your own separate notes before those personal hosts will resolve. The one other manual step chezmoi can't do: open each SSH Key item in 1Password (or drag the key file onto the 1Password window if a key isn't in the vault yet) so it's available to drag/import — the keys themselves live in your 1Password account and sync there, not through this repo.

### AWS credentials

The `smittoid` IAM user's access key lives in a 1Password "AWS Access Key" item in the Development vault, used via `op`'s AWS CLI shell plugin rather than a static `~/.aws/credentials` file:

- `run_once_after_25-install-awscli.sh` installs the `aws` binary itself (see [What's here](#whats-here)) — the shell plugin below just wraps it.
- `private_dot_aws/private_config` → `~/.aws/config` (just the default region — no secrets, `private_` prefix keeps it `0600`).
- `~/.config/op/plugins.sh` is generated by `op plugin init aws` (not tracked here — it's local, regenerated per machine) and aliases `aws` to a function that fetches credentials from 1Password with a Touch ID prompt per use.
- `dot_zshrc` sources it (guarded with an existence check) **after** oh-my-zsh loads, so the 1Password-wrapped `aws` function overrides oh-my-zsh's bundled `aws` plugin rather than the other way around — get this ordering wrong and `aws` silently falls back to the (now-deleted) static credentials file.

**New machine**: after `chezmoi apply` and signing into 1Password, three manual gates the OS/1Password require before the CLI shell plugin can reach the desktop app — none are scriptable:

1. **1Password app → Settings (⌘,) → Developer → "Integrate with 1Password CLI"**. Separate toggle from "Use the SSH Agent" (which SSH keys need); the CLI shell plugin needs this one.
2. **System Settings → Privacy & Security → Full Disk Access → add iTerm2** (or whichever terminal you use), then **fully quit** iTerm2 (⌘Q) and reopen. Without this, `op` can't read the desktop app's settings file inside `~/Library/Group Containers/2BUA8C4S2C.com.1password/` and fails with `operation not permitted` (visible via `OP_DEBUG=1 op whoami`) — a plain "close window" isn't enough; the TCC grant only applies to freshly-launched processes.
3. **Run `op signin` once** to trigger the Touch ID unlock and open the session; then `op whoami` should print the account, and `op plugin init aws` will work.

Then run `op plugin init aws` once, choose "Import" and paste in the access key, save it to the Development vault. A fresh terminal will then pick up the `aws` alias, and the first `aws <anything>` call will prompt you to locate the credential item and unlock it with Touch ID.

**Note**: this is still a long-lived IAM access key, just no longer sitting in plaintext on disk — 1Password's biometric gate is the security improvement, not short-lived credentials. AWS CLI v2 also supports true temporary credentials via IAM Identity Center (SSO) if that's ever worth the bigger setup lift (Console-side permission sets, user assignment) — not pursued yet.

## iTerm2 profile

Two separate pieces of iTerm state are tracked here:

- **Colors** — `init/Solarized Dark.itermcolors` is a color-preset file, imported by `run_once_after_30-import-app-settings.sh` (opens iTerm which prompts to import). Select it in Settings → Profiles → Colors after import.
- **Everything else** (font, keybindings, cursor, window behavior, session settings) — via iTerm2's **Dynamic Profiles** feature: any JSON file dropped into `~/Library/Application Support/iTerm2/DynamicProfiles/` is auto-loaded at launch. `run_onchange_after_35-install-iterm-profile.sh` installs `init/iterm-profile.json` there when present.

**Populating `init/iterm-profile.json`** (do this once on the machine that has your good profile — the JSON is checked into the public repo, so keep out anything sensitive):

1. iTerm2 → Settings → Profiles → *select your profile* → **Other Actions** ▾ → **Save Profile as JSON**.
2. **Wrap the exported file as `{"Profiles": [ <exported object> ] }`** before saving it as `init/iterm-profile.json`. The export button gives you the bare profile object (the format iTerm uses for copy/paste between installations), but the Dynamic Profiles loader that `run_onchange_after_35` targets only recognizes the array-wrapped form — an unwrapped file is silently ignored, not an error, so it's easy to miss.
3. Save the result to `init/iterm-profile.json` in this repo.
4. Commit + push.
5. On other machines: `chezmoi update`. The `run_onchange` script hashes the JSON and re-runs when it changes, so profile edits propagate on the next apply.

Colors and the Dynamic Profile can coexist: import the color preset once, then in Settings → Profiles select the dynamic profile as default. The dynamic profile picks up whichever color preset is active at export time.

## Thanks to…

This repo started as a fork of [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles) — see that project for the full list of original credits and inspirations.
