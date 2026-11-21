# Installs WSL2 with Ubuntu 24.04 when it is missing. Development on the
# Windows box happens inside it; there, the Linux steps in the README apply
# this repo a second time. Exits at once when the distro already exists.
#
# `wsl --install` asks for elevation (UAC) and usually wants a reboot before
# the distro can start. A failure leaves the script unrecorded, so chezmoi
# runs it again on the next apply. wsl.exe prints UTF-16, hence the NUL strip.
$ErrorActionPreference = 'Continue'
$distro = 'Ubuntu-24.04'

$null = wsl --status 2>&1
if ($LASTEXITCODE -eq 0) {
    $installed = (wsl --list --quiet 2>&1 | Out-String) -replace "`0", ''
    if ($installed -match [regex]::Escape($distro)) { exit 0 }
}

wsl --install --distribution $distro --no-launch
if ($LASTEXITCODE -ne 0) {
    Write-Output "wsl --install exited with $LASTEXITCODE."
    exit $LASTEXITCODE
}
Write-Output "wsl: $distro installed. Reboot if asked, open $distro once to create the Linux user, then follow the Linux steps in the README inside it."
