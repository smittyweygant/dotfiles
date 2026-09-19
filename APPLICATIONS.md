# Applications not covered by the Brewfile / MASfile

Homebrew casks are tracked in `Brewfile`; Mac App Store apps in `MASfile`. This file records everything else: what needs a manual install, what was deliberately left behind when moving to the work MacBook (2026-09), and what's still undecided.

## Manual installs (not scriptable)

- **Microsoft Defender / Okta Verify** — deployed by IT/MDM, not installed by hand. Check Self Service / ask IT.

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

Don't reinstall/reconfigure blindly, revisit first: `.asdf` vs `.nvm`/`.pyenv` overlap, `.sf` (Salesforce CLI — moot if Salesforce is dropped), `.odbc.ini`/`.odbcinst.ini`, `.config/temporalio`/`.config/tcld` (moot if Temporal is dropped), the stale `withfig.fig` VS Code extension (Fig was sunset).
