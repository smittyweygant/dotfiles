# Merges init/windows-terminal.json into Windows Terminal's settings.json and
# makes the WSL distro the default profile. Terminal owns that file and
# rewrites it whenever a setting changes in the UI, so it is not a chezmoi
# target; this script changes only the keys the fragment names, plus the
# default profile under the rule below.
#
# It runs on every apply, not on change: the WSL profile exists only after WSL
# is installed and Terminal has been opened once, which may be later than the
# first apply. It writes only when the result differs, so repeats are no-ops.
#
# Terminal allows comments and trailing commas in settings.json; Windows
# PowerShell 5.1's JSON parser does not. PowerShell 7 reads them, so the script
# re-runs itself there when it can. A rewrite drops the comments, as any JSON
# round trip would. Terminal itself writes none.
$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSVersion.Major -lt 7) {
    $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($pwsh) {
        & $pwsh.Source -NoLogo -NoProfile -NonInteractive -File $PSCommandPath
        exit $LASTEXITCODE
    }
}

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

try {
    $settings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
} catch {
    Write-Output "windows-terminal: could not parse $settingsPath ($($_.Exception.Message)). Install PowerShell 7 or remove the comments, then run chezmoi apply again."
    exit 0
}
$before = $settings | ConvertTo-Json -Depth 32

# Old settings files list profiles as a bare array; Terminal still reads that
# form. Lift it into the current object form so the merge has a place to go.
if ($settings.profiles -is [array]) {
    $settings | Add-Member -NotePropertyName profiles -NotePropertyValue ([pscustomobject]@{ list = $settings.profiles }) -Force
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

$fragmentPath = Join-Path $env:CHEZMOI_SOURCE_DIR 'init\windows-terminal.json'
Merge-Into $settings (Get-Content -LiteralPath $fragmentPath -Raw | ConvertFrom-Json)

# Terminal generates one profile per WSL distro, with per-machine GUIDs, so the
# default is chosen by source rather than hard-coded. Ubuntu wins if present.
# The default changes only while it is still Terminal's own: unset, pointing at
# a profile that no longer exists, or the factory Windows PowerShell profile.
# A default picked by hand in the UI is left alone.
$factoryDefault = '{61c54bbd-c2c6-5271-96e7-009a87ff44bf}'
$profiles = @($settings.profiles.list)
$current = $settings.defaultProfile
$stillFactory = (-not $current) -or ($current -eq $factoryDefault) -or
    (-not ($profiles | Where-Object { $_.guid -eq $current }))
$wsl = @($profiles | Where-Object { $_.source -eq 'Windows.Terminal.Wsl' -and -not $_.hidden })
if ($wsl.Count -eq 0) {
    Write-Output 'windows-terminal: no WSL profile yet; default profile left as is.'
} elseif ($stillFactory) {
    $pick = @($wsl | Where-Object { $_.name -like 'Ubuntu*' }) + $wsl | Select-Object -First 1
    $settings | Add-Member -NotePropertyName defaultProfile -NotePropertyValue $pick.guid -Force
}

$after = $settings | ConvertTo-Json -Depth 32
if ($after -ne $before) {
    [IO.File]::WriteAllText($settingsPath, $after, (New-Object Text.UTF8Encoding $false))
    Write-Output "windows-terminal: updated $settingsPath"
}
