# Cross-platform plan

One bootstrap per machine type: Mac, Linux dev boxes, and a Windows desktop.
Shared things stay shared. Each OS stays plain and readable. The Pi, router
and EC2 hosts are out of scope.

## Decision: tiered unification

1. **Universal:** claude-config, git config, editorconfig, vim, 1Password.
2. **POSIX layer** (Mac, Linux, WSL): zsh, aliases, functions, tmux, the
   `aws-*` scripts.
3. **Per-OS, thin and separate:** Brewfile, MASfile and macOS defaults on the
   Mac; an apt list on Linux; a winget list and Windows Terminal settings on
   Windows.

**Gate by file, not by template.** `.chezmoiignore`, templated on
`.chezmoi.os`, decides which files and `run_*` scripts apply. Dotfiles carry
no scattered `{{ if eq .chezmoi.os }}` blocks. Use a template conditional only
where one file differs by a line or two.

Both Claude profiles, personal and work, go on every dev machine, Windows
included. On Windows, WSL2 comes first: it is the Linux path plus a thin host
layer. Native Windows Claude Code is a gated phase, done only if two weeks of
real work in WSL show it is needed.

## Phases

| # | Repo | Phase |
|---|------|-------|
| 1 | dotfiles #3 | Gate Mac-only files and scripts by OS. No change on the Mac. |
| 2 | dotfiles #4 | Linux and WSL2 layer: apt list, Linux paths for the scripts below, 1Password SSH agent (Linux agent, or `ssh.exe` in WSL). |
| 3 | dotfiles #5 | Thin Windows host layer: winget import, Windows Terminal settings, `.gitconfig`, bootstrap steps in the README. |
| 4 | claude-config #38 | Native Windows, only if the WSL trial calls for it: `install.py`, PowerShell `claude-personal` / `claude-work`. |

## Assumptions to verify

- Native Claude Code on Windows runs hook commands through Git Bash, so `.sh`
  hooks work. Check before phase 4.
- Symlinks on native Windows need Developer Mode. claude-config's
  profile-symlink scheme depends on them.
- In WSL, git and ssh reach the Windows 1Password agent through `ssh.exe`
  (`core.sshCommand`). A standalone Linux box uses 1Password's Linux agent.
- The `claude-personal` / `claude-work` wrappers live in zsh. Native Windows
  would need PowerShell twins.

## Scripts

Target names, without the `run_*` prefix. Mac-only scripts are listed in
`.chezmoiignore` off darwin; Linux-only ones off linux; the PowerShell ones
off windows. On windows every `.sh` is ignored, shared or not: there is no
bash to run them, and the host does not want what they install.

| Script | Class | Why |
|--------|-------|-----|
| 05-create-vim-dirs | shared | `mkdir` only. |
| 06-enable-touchid-sudo | Mac-only | Touch ID and `/etc/pam.d/sudo_local`. |
| 10-install-apt-packages | Linux-only | The Aptfile, pyenv, zsh as login shell. |
| 10-install-packages | Mac-only | Homebrew and the Brewfile. |
| 10-install-winget-packages | Windows-only | `winget import` of winget.json. PowerShell. |
| 10-macos-defaults | Mac-only | `defaults write`. |
| 12-configure-windows-terminal | Windows-only | Merges `init/windows-terminal.json` into Terminal's settings and makes WSL the default profile. Every apply, idempotent. |
| 15-install-python | shared | pyenv from the Brewfile, or `~/.pyenv` on Linux. |
| 20-install-mas-apps | Mac-only | Mac App Store. |
| 20-install-zsh-framework | shared | `git clone` only. |
| 25-install-awscli | shared | AWS's installer handles Linux; needs `unzip`. |
| 26-configure-aws-sso | shared | Runs `aws-sso-setup`. |
| 26-install-sdkman | shared | SDKMAN supports Linux; needs `zip` and `unzip`. |
| 27-install-nx-tether | Mac-only | `.dmg` and `installer`. |
| 30-import-app-settings | Mac-only | iTerm and Dropbox under `/Applications`. |
| 35-install-iterm-profile | Mac-only | iTerm. |
| 40-install-claude-config | shared | bash, python3, git. |
| 41-enable-git-hooks | shared | `git config`. |
| 42-sync-ssh-pubkeys | shared | Skips without `op`. Needs bash 4 (`mapfile`). |
| 43-install-claude-code | Linux-only | Native installer. Runs after claude-config so `~/.claude` is already its symlink. |
| 45-clone-call-analysis-repos | Mac-only | Feeds the WhisperX recorder. |
| 50-setup-call-analysis-venv | Mac-only | Same. |
| 55-seed-obs-keychain | Mac-only | macOS Keychain (`security`). |

The WhisperX recorder and `~/.config/whisperx` are Mac-only too.

## Windows host

Windows gets `.gitconfig`, `.gitconfig-akka`, `.editorconfig` and the two
scripts above; `.chezmoiignore` lists everything else off. Windows Terminal
rewrites its `settings.json` itself, so the file is not a chezmoi target; the
script merges a fragment into it instead. chezmoi needs `.chezmoi.toml.tmpl`
to run `.ps1` scripts at all: Windows PowerShell's default execution policy
is Restricted, and the template gives chezmoi's interpreter a per-process
Bypass. The template renders empty on other systems.

## 1Password SSH

`.chezmoitemplates/is-wsl` is the one WSL check. `.ssh/config` and
`.gitconfig` read it:

- Mac: `IdentityAgent` is the Group Containers socket.
- Linux: `IdentityAgent` is `~/.1password/agent.sock`.
- WSL: no `IdentityAgent`; git sets `core.sshCommand = ssh.exe`, which uses
  the Windows agent and the Windows `~/.ssh/config`.

`.aliases` and `.functions` still hold some Mac commands (`pbcopy`,
`osascript`, `brew`). They fail only when called.
