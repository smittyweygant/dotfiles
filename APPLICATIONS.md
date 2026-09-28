# Applications not covered by the Brewfile / MASfile

Homebrew casks are tracked in `Brewfile`; Mac App Store apps in `MASfile`. This file records everything else: what needs a manual install, what was deliberately left behind when moving to the work MacBook (2026-09), and what's still undecided.

## Manual installs (not scriptable)

- **Microsoft Defender / Okta Verify** — deployed by IT/MDM, not installed by hand. Check Self Service / ask IT.
- **obs-cmd** (CLI control for OBS, used by the whisperx recorder) — no Homebrew formula or cask exists (confirmed via `brew search obs-cmd` against core plus the `akka/brew` and `common-fate/granted` taps already added on this machine). Download the release binary for your architecture from [grigio/obs-cmd](https://github.com/grigio/obs-cmd/releases) (`obs-cmd-x64-macos.tar.gz` Intel / `obs-cmd-arm64-macos.tar.gz` Apple Silicon), `chmod +x`, and place it on `PATH` (e.g. `~/.local/bin`). See `call-analysis/README.md` and `USER_GUIDE.md` for exact commands.

## SwiftBar

`swiftbar` is already a cask in the `Brewfile`. On a fresh machine it still needs its plugin folder pointed at the call-analysis-suite plugin — SwiftBar stores that path in its own preferences, which isn't scriptable from dotfiles:

- Point SwiftBar plugin folder at `~/development/call-analysis-suite/call-analysis/SwiftBarPlugins/` via SwiftBar preferences.

See `~/development/call-analysis-suite/call-analysis/USER_GUIDE.md` (Installation section) for the full setup context, including the OBS/WhisperX pieces dotfiles do automate (repo clone, venv, Keychain seed).

## First-run: enable "Open at Login"

macOS 13+ manages this via SMAppService (per-app registration), so it can't be reliably scripted from dotfiles. On the new Mac, enable each of these in System Settings → General → Login Items → Open at Login, or accept the prompt each app shows on first launch:

- **Amphetamine** (MAS)
- **SwiftBar** (Homebrew cask) — menu-bar-only, so basically required
- **Cloudflare WARP** (Homebrew cask)

## Deliberately left behind on the old MacBook

Not carried over to the work Mac. Still in git history (`Brewfile`, `MASfile`, earlier versions of this file) if you ever want them back.

- **Salesforce / Apex tooling**: all `salesforce.*` VS Code extensions, `financialforce.lana`
- **Hugo / Temporal / protobuf**: formulae and the Hugo VS Code extensions
- **Virtualization**: VirtualBox, `docker-machine` (poor fit on Apple Silicon; Docker Desktop covers containers)
- **Tailscale formula**: replaced by the `tailscale-app` cask, which bundles the CLI — running both conflicts
- **Personal comms/media**: Signal, Monal, Spotify, VLC, Plex, qBittorrent, Transmission, 2FHey (1Password and macOS's Passwords app both generate 2FA codes natively)
- **Adobe**: Creative Cloud, Acrobat DC, Lightroom CC/Classic, Photoshop
- **Hobby hardware**: Arduino IDE, Android Studio, VictronConnect, Raspberry Pi Imager, Elgato Camera Hub, DisplayLink Manager, Epson/Nikon software
- **Networking**: NordVPN, VIP Access, Tor Browser
- **Misc**: Beyond Compare, HackerRank, VSee, `.arduinoIDE`
- **Dev/utility casks dropped in the final pass**: KeyCastr, ngrok, Sequel Ace, Sublime Text (and its `init/Preferences.sublime-settings`), Raycast

## Added after review

Claude desktop, Claude Code, ChatGPT, Codex, and OneDrive are now casks in the `Brewfile`. Claude Code via the cask is Homebrew-managed (update with `brew upgrade`), unlike the auto-updating native installer used on the old Mac. `~/projects` is a symlink into `~/OneDrive/Projects` on the old Mac — sort that out separately; nothing here creates it.

## Still undecided

- VS Code Insiders (`visual-studio-code@insiders`) — still used, or drop in favor of stable? Not in the `Brewfile`.
- Kept by design: Amphetamine and 1Password for Safari (both in `MASfile`).

## Open follow-ups from the original survey

Don't reinstall/reconfigure blindly, revisit first: `.asdf` vs `.nvm`/`.pyenv` overlap, `.sf` (Salesforce CLI — moot if Salesforce is dropped), `.odbc.ini`/`.odbcinst.ini`, `.config/temporalio`/`.config/tcld` (moot if Temporal is dropped).
