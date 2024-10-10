# Enable Windows firewall

# Set GPOs for the firewall
. "$PSScriptRoot\..\util\Set-Gpo.ps1" `
    -Path "Network\Network Connections\Windows Defender Firewall\Domain Profile\Windows Defender Firewall: Protect all network connections" `
    -Value 1 `
    -Type "DWORD"

. "$PSScriptRoot\..\util\Set-Gpo.ps1" `
    -Path "Network\Network Connections\Windows Defender Firewall\Standard Profile\Windows Defender Firewall: Protect all network connections" `
    -Value 1 `
    -Type "DWORD"

Write-Host "Make sure to refresh the group policy settings." -ForegroundColor Yellow

$firewall = Get-NetFirewallProfile

foreach ($profile in $firewall | Where-Object { $_.Enabled -eq "False" }) {
    Write-Host "Enabling firewall profile '$($profile.Name)'"
    try {
        Set-NetFirewallProfile -Profile $profile.Name -Enabled True
    }
    catch {
        Write-Error "Error occurred: $_"
    }
}

foreach ($profile in $firewall) {
    # Ingress traffic should be blocked
    try {
        Write-Host "Blocking ingress traffic for profile '$($profile.Name)'"
        Set-NetFirewallProfile -Profile $profile.Name -DefaultInboundAction Block
    }
    catch {
        Write-Error "Error occurred: $_"
    }

    # Outgoing traffic should be allowed
    try {
        Write-Host "Allowing outbound traffic for profile '$($profile.Name)'"
        Set-NetFirewallProfile -Profile $profile.Name -DefaultOutboundAction Allow
    }
    catch {
        Write-Error "Error occurred: $_"
    }
}

Write-Host "Firewall enabled." -ForegroundColor Green