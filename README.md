# Smitty's dotfiles

Personal macOS toolchain and configuration, managed with [chezmoi](https://www.chezmoi.io/). Originally forked from [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles); restructured to be reproducible on a fresh machine.

## What's here

- Shell config (zsh + oh-my-zsh + Powerlevel10k), editor config (vim), git config, and assorted CLI tool dotfiles — all managed as `dot_*` files that chezmoi renders into `$HOME`.
- `private_dot_ssh/config` + `dot_config/private_1Password/ssh/agent.toml` — SSH client config and 1Password SSH agent scoping. No private keys are ever tracked here; see [SSH keys](#ssh-keys) below.
- `run_once_before_10-macos-defaults.sh.tmpl` — macOS system preference tweaks (`defaults write` commands), runs once on a fresh machine.
- `run_once_before_05-create-vim-dirs.sh` — creates vim's backup/swap/undo directories.
- `run_once_after_20-install-zsh-framework.sh` — clones oh-my-zsh, Powerlevel10k, and the custom zsh plugins `.zshrc` expects.
- `run_once_after_25-install-awscli.sh` — installs AWS CLI v2 via [AWS's official install script](https://awscli.amazonaws.com/v2/install.sh), not Homebrew (its community `awscli` formula lags behind official releases).
- `run_once_after_26-configure-aws-sso.sh` — prompts for your AWS Identity Center details and adds the SSO profiles; see [AWS credentials](#aws-credentials).
- `run_once_after_30-import-app-settings.sh.tmpl` — iTerm2 color preset and other tweaks that need the apps installed first.
- `run_onchange_after_35-install-iterm-profile.sh.tmpl` — installs `init/iterm-profile.json` as an iTerm2 Dynamic Profile (font, keybindings, cursor, window behavior — everything the `.itermcolors` preset alone doesn't cover). Re-runs when the profile JSON changes. See [iTerm2 profile](#iterm2-profile) for the export flow.
- `Brewfile` + `run_onchange_10-install-packages.sh.tmpl` — Homebrew formulae/casks, reinstalled automatically whenever the Brewfile changes.
- `run_onchange_after_15-install-python.sh` — installs the Python version used by project `.python-version` files through pyenv, without changing pyenv's global version.
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
   The **CLI integration** side needs one extra bit beyond the toggle — see [AWS credentials](#aws-credentials) for the full 3-step Full Disk Access dance. It can wait until step 6, but `op read` runs at shell startup, so it's easier to knock out here.
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
   - AWS Identity Center details (prompted by `aws-sso-setup`) and sign-in — see [AWS credentials](#aws-credentials).
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

### Node.js

The Brewfile installs and links Homebrew's current Node.js as the bootstrap default, along with
pnpm and Yarn. `nvm` remains available for projects that need a different Node version, but a
fresh `chezmoi apply` does not depend on an nvm version already being installed.

Python projects use pyenv. Chezmoi installs Python 3.12.8 for project-local selection, while
leaving the global pyenv version unchanged.

## Secrets

- Shell env secrets (API keys, tokens) are pulled lazily in `dot_zshrc` via `op read 'op://...'` at shell startup — never rendered into the file itself and never committed.
- AWS uses IAM Identity Center sign-in (short-lived role credentials), not a static `~/.aws/credentials` file — see [AWS credentials](#aws-credentials) below.

### SSH keys

All private keys live in the **Development** vault in 1Password — none are stored in `~/.ssh` or this repo. The 1Password SSH agent serves them transparently:

- `private_dot_ssh/config` sets `IdentityAgent` to 1Password's socket (`~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`) under the catch-all `Host *` block, and includes `github.com` directly (nothing sensitive there). Per-host `IdentityFile` lines point at `.pub` files only — these just pin *which* key to offer for a given host; the agent supplies the actual private material.
- `dot_config/private_1Password/ssh/agent.toml` scopes the agent to the Development vault (`vault = "Development"`). Creating a custom `agent.toml` overrides 1Password's default vault behavior, so every key that should be available over SSH needs to live in that vault — dropping a new key into a different vault silently won't show up in `ssh-add -l` until moved.
- `private_dot_ssh/.gitignore` is a repo-only allowlist (`config` and `*.pub` only) so this directory can never accidentally pick up a real private key, even if something is copied in carelessly later. It's not deployed to `$HOME` itself — chezmoi skips literal dotfiles in the source tree.
- **Personal infra (home LAN IPs, EC2 hostnames, Tailscale FQDN) lives in `~/.ssh/config.local`, gitignored and never part of this public repo at all** — not obfuscated/templated, just not tracked. `private_dot_ssh/config` pulls it in via `Include config.local` as the very **first** line in the file — OpenSSH (tested on 10.2p1/LibreSSL) silently ignores an `Include` that comes after any `Host` block, so don't reorder this.
- `run_after_42-sync-ssh-pubkeys.sh` runs on every `chezmoi apply`. It reads `~/.ssh/config.local` for `IdentityFile ~/.ssh/<name>.pub` lines, and for any `.pub` stub that doesn't exist locally yet, looks up a 1Password SSH Key item in the Development vault whose title contains `<name>` and writes the stub from its public key field. Without the matching stub, ssh can't tell the agent which key to offer for that host — it falls back to offering *every* key the agent holds, which can exceed the server's `MaxAuthTries` before reaching the right one (seen first-hand: "Too many authentication failures" with no Touch ID prompt, because the matching key was never tried). The script is a no-op if `config.local` doesn't exist yet, if a stub already exists, or if 1Password's authorization times out (retries silently on the next apply) — it never blocks `chezmoi apply`.

**New machine**: after signing into the 1Password app (step 2 above) and running `chezmoi apply`, `private_dot_ssh/config` and `agent.toml` land automatically, but `~/.ssh/config.local` does not — it's deliberately never in this repo (not even in git history), so recreate it by hand from memory/your own separate notes before those personal hosts will resolve. Once it's in place, the next `chezmoi apply` (or running `run_after_42-sync-ssh-pubkeys.sh` directly) backfills the `.pub` stubs for any key that's already in the Development vault. The one manual step that's never scriptable: if a key isn't in 1Password yet at all, open it in the 1Password app (or drag the key file onto the window) so it's actually there to match against — the keys themselves live in your 1Password account and sync there, not through this repo.

### AWS credentials

AWS access goes through IAM Identity Center. No long-lived key sits on disk or behind a shell wrapper. Two Identity Center users share one account, each with its own sign-in:

- **You** sign in as your own user (`aws sso login --sso-session admin`) and get the `Admin` permission set.
- **Claude** signs in as a separate `claude` user (`aws sso login --sso-session claude --no-browser`, then open the URL in a private window as that user). It holds `ClaudeDev` (read-only) permanently. `claude-personal` launches with `AWS_PROFILE=claude-dev`.
- **Write access** is `ClaudeElevated` (EC2, ECR, SSM, Route 53, and get/put on the `releases/`, `backups/` and `models/` prefixes of the finances bucket, with no delete; Parameter Store `/finances/*` is denied and `StartSession` is denied, but `SendCommand` is allowed, so a command run on the host can still reach its secrets; review the command before you elevate). It is assigned to the `claude` user only on request: `claude-elevate [minutes]` grants it, then revokes it after the timer (default 30). `claude-elevate off` revokes now. Revoking removes the role, so issued credentials die at once. It needs your admin sign-in.

How it is wired:

- `run_once_after_25-install-awscli.sh` installs the `aws` binary itself (see [What's here](#whats-here)).
- `private_dot_aws/create_private_config` seeds `~/.aws/config` with the default region on a new machine and never touches it again (`create_` writes only when the file is missing; `private_` keeps it `0600`). The AWS CLI has no include directive, so this stands in for a `.local` file.
- `run_once_after_26-configure-aws-sso.sh` runs `aws-sso-setup`, which prompts for your organization's account ID, Identity Center instance ARN, identity store ID, portal URL and the two user names. It saves them to `~/.config/aws-sso/env` (never in this repo) and appends the profiles from `init/aws-sso/config.tmpl` to `~/.aws/config`. Re-run `aws-sso-setup` by hand to change an answer.
- `aws-elevate on|off` (installed to `~/.local/bin`) reads that env file. `claude-elevate` in `dot_functions` wraps it with a timer.
- `init/aws-sso/create-permission-sets.sh` is the one-time setup for a new organization: it creates the three permission sets from `ClaudeElevated-inline-policy.json` and assigns them. Create the two users in the console first.

**New machine**: after `chezmoi apply` and signing into 1Password, three manual gates the OS/1Password require before `op` can reach the desktop app (needed for `op read` at shell startup) — none are scriptable:

1. **1Password app → Settings (⌘,) → Developer → "Integrate with 1Password CLI"**. Separate toggle from "Use the SSH Agent" (which SSH keys need); `op` needs this one.
2. **System Settings → Privacy & Security → Full Disk Access → add iTerm2** (or whichever terminal you use), then **fully quit** iTerm2 (⌘Q) and reopen. Without this, `op` can't read the desktop app's settings file inside `~/Library/Group Containers/2BUA8C4S2C.com.1password/` and fails with `operation not permitted` (visible via `OP_DEBUG=1 op whoami`) — a plain "close window" isn't enough; the TCC grant only applies to freshly-launched processes.
3. **Run `op signin` once** to trigger the Touch ID unlock and open the session; then `op whoami` should print the account.

`chezmoi apply` then prompts for the organization details (or run `aws-sso-setup` later) and you sign in as above.

**Note**: Claude's deny rules (in the `claude-config` repo) block the admin profile, the SSO token cache and `aws sso login`, but they are guardrails. SSO tokens sit in `~/.aws/sso/cache`, readable by anything running as you. The separate `claude` user means its own token cannot mint admin credentials.

### Claude Code profiles

Claude Code's personal and work **logins** are isolated with `CLAUDE_CONFIG_DIR`, so switching profiles is really switching which Anthropic account — and which plan's quota — a session draws against:

- `claude-personal [args...]` always authenticates as the separate `~/.claude-personal` profile.
- `claude-work [args...]` always authenticates as the separate `~/.claude-work` profile.
- `claude-profile work` makes plain `claude` use the work profile for the rest of the current shell. `claude-profile personal` switches it back, and `claude-profile status` shows the current selection.

Everything except auth is shared between the two: CLAUDE.md, settings, hooks, skills, and full session history live once in `~/.claude-shared` (see the `claude-config` repo's `install.sh`), symlinked into both profile directories. So a thread started under `claude-personal` is just as visible and resumable under `claude-work`, and vice versa — switching profiles only changes which account is paying, not which config or history you see. Only auth credentials and the `akka-mcp-gateway` MCP registration stay genuinely separate per profile, since Claude Code keys both to `$CLAUDE_CONFIG_DIR` itself.

`~/.claude` — the fallback Claude Code uses whenever `$CLAUDE_CONFIG_DIR` isn't set (a bare `claude` in a shell that never ran `claude-profile`, an IDE integration, a background job) — is itself a symlink to `~/.claude-personal`, installed by `claude-config`'s `install.sh`. So any invocation that bypasses the wrapper functions lands on the personal account, never work, by construction rather than convention.

After applying the dotfiles and opening a new shell, run each wrapper once and complete `/login`. Claude creates the profile directories as needed. Project-level `.claude/` files still apply to both.

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
