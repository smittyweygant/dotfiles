# Manually-installed applications

Apps installed outside Homebrew and outside the Mac App Store — direct download, vendor installer, or MDM. These can't be reliably scripted (license gates, custom installers), so this is a checklist to work through by hand on a new machine, not automation.

(Homebrew casks are tracked in `Brewfile`; Mac App Store apps are tracked in `MASfile` — neither needs to be repeated here.)

## Adobe
- Adobe Creative Cloud (installs the rest below)
- Acrobat DC
- Lightroom CC
- Lightroom Classic
- Photoshop 2025

## Microsoft 365
- Excel, Word, PowerPoint, Outlook, OneNote, Teams
- OneDrive
- Microsoft Defender

## AI / dev tools
- ChatGPT
- Claude (desktop app)
- Cursor
- HackerRank (interview tooling)

## Browsers
- Google Chrome
- Tor Browser

## Communication / media
- Slack
- Spotify
- Zoom (zoom.us)
- 2FHey
- VSee

## Hardware / peripherals
- DisplayLink Manager
- Elgato Camera Hub
- Epson Software
- Nikon Software
- Arduino IDE (if the hobby project is still active — flagged as unsure in the original survey)

## Networking / remote access
- NordVPN
- Tailscale.app (the CLI is in `Brewfile`; the menu-bar app itself is a separate direct-download install)
- VIP Access (Symantec 2FA token)

## Torrenting / media servers
- Plex
- qBittorrent
- Transmission
- OBS

## Misc
- 1Password (desktop app — the CLI is in `Brewfile` as `1password-cli`)
- Beyond Compare
- Dropbox
- GIMP
- Raspberry Pi Imager

---

**Follow-up items from the original survey, not yet decided** (don't reinstall/reconfigure blindly, revisit first): `.asdf` vs `.nvm`/`.pyenv` overlap, `.vscode-insiders` (still used, or drop in favor of stable VS Code?), `.sf` (Salesforce CLI — active project?), `.odbc.ini`/`.odbcinst.ini`, `.config/temporalio`/`.config/tcld` (still using Temporal?).
