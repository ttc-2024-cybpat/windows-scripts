# Enable real-time protection
Set-MpPreference -DisableRealtimeMonitoring 0 `
    -DisableBehaviorMonitoring 0 `
    -DisableIOAVProtection 0

Write-Host "Enabled Defender real-time protection." -ForegroundColor Green

# Review exclusions. We don't want to remove an exclusion for the scoring engine (yikes!)
$exclusions = Get-MpPreference | Select-Object -ExpandProperty ExclusionPath
foreach ($exclusion in $exclusions) {
    Write-Host "Found exclusion: $exclusion"
    Write-Host "Remove? [Y/n] " -ForegroundColor Yellow -NoNewline
    $response = Read-Host
    if ($response -match "^[Yy]") {
        Remove-MpPreference -ExclusionPath $exclusion
    }
}

Write-Host "Removed exclusions." -ForegroundColor Green

# Enable SmartScreen and set up levels
. "$PSScriptRoot\..\util\Write-Registry.ps1" `
    -Key "HKLM\Software\Policies\Microsoft\Windows\System" `
    -ValueName "EnableSmartScreen" `
    -Value 1 `
    -Type "DWORD"
. "$PSScriptRoot\..\util\Write-Registry.ps1" `
    -Key "HKLM\Software\Policies\Microsoft\Windows\System" `
    -ValueName "ShellSmartScreenLevel" `
    -Value "Warn" `
    -Type "String"

Write-Host "Enabled Defender SmartScreen." -ForegroundColor Green