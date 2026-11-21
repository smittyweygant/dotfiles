# Merges init/windows-terminal.json into Windows Terminal's settings.json and
# makes the WSL distro the default profile. Terminal owns that file and
# rewrites it whenever a setting changes in the UI, so it is not a chezmoi
# target; this script changes only the keys the fragment names.
#
# It runs on every apply, not on change: the WSL profile exists only after WSL
# is installed and Terminal has been opened once, which may be later than the
# first apply. It writes only when the result differs, so repeats are no-ops.
$ErrorActionPreference = 'Stop'

$candidates = @(
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
)
$settingsPath = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $settingsPath) {
    Write-Output 'windows-terminal: no settings.json yet. Open Windows Terminal once, then run chezmoi apply again.'
    exit 0
}

# Recursive merge: objects merge key by key, anything else is replaced.
function Merge-Into($target, $source) {
    foreach ($property in $source.PSObject.Properties) {
        $existing = $target.PSObject.Properties[$property.Name]
        if ($existing -and $existing.Value -is [PSCustomObject] -and $property.Value -is [PSCustomObject]) {
            Merge-Into $existing.Value $property.Value
        } else {
            $target | Add-Member -NotePropertyName $property.Name -NotePropertyValue $property.Value -Force
        }
    }
}

$raw = Get-Content -LiteralPath $settingsPath -Raw
$settings = $raw | ConvertFrom-Json
$before = $settings | ConvertTo-Json -Depth 32

$fragmentPath = Join-Path $env:CHEZMOI_SOURCE_DIR 'init\windows-terminal.json'
Merge-Into $settings (Get-Content -LiteralPath $fragmentPath -Raw | ConvertFrom-Json)

# Terminal generates one profile per WSL distro, with per-machine GUIDs, so the
# default is chosen by source rather than hard-coded. Ubuntu wins if present.
$wsl = @($settings.profiles.list | Where-Object { $_.source -eq 'Windows.Terminal.Wsl' -and -not $_.hidden })
if ($wsl.Count -gt 0) {
    $pick = @($wsl | Where-Object { $_.name -like 'Ubuntu*' }) + $wsl | Select-Object -First 1
    $settings | Add-Member -NotePropertyName defaultProfile -NotePropertyValue $pick.guid -Force
} else {
    Write-Output 'windows-terminal: no WSL profile yet; default profile left as is.'
}

$after = $settings | ConvertTo-Json -Depth 32
if ($after -ne $before) {
    [IO.File]::WriteAllText($settingsPath, $after, (New-Object Text.UTF8Encoding $false))
    Write-Output "windows-terminal: updated $settingsPath"
}
