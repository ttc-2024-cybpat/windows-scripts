# Enable Windows defender

Write-Host "Installing Windows Defender..."

# Yes, you can literally delete Windows Defender in Windows Server.
Dism /Online /Enable-Feature /FeatureName:Windows-Defender /Quiet /NoRestart | Out-Null

# Check error
if ($LASTEXITCODE -ne 0) {
    Write-Host "Windows Defender package not available." -ForegroundColor Yellow
    Write-Host "If this is not a Windows Server machine, this is fine." -ForegroundColor Yellow
}
else {
    Write-Host "Reboot the system to complete Windows Defender installation." -ForegroundColor Yellow
}

# Set group policy
. "$PSScriptRoot\..\util\Set-Gpo.ps1" `
    -Path "Windows Components\Windows Defender Antivirus\Turn off Windows Defender Antivirus" `
    -Value 1 `
    -Type "DWORD"

Write-Host "Windows Defender enabled." -ForegroundColor Green