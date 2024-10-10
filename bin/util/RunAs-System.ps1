# Elevate to NT AUTHORITY\SYSTEM using PsExec

param (
    [string]$ScriptPath
)

# Ensure PSTools is installed
$pstoolsPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\opt\pstools'
if (-not (Test-Path $pstoolsPath)) {
    Write-Host "PSTools not found. Installing..."
    . "$PSScriptRoot\Install-PSTools.ps1"
}

# Get the path to PowerShell (this works for both PowerShell and pwsh)
$pwsh = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
#Write-Host "Current PowerShell Path: $pwsh"

# Check if the script path is provided and exists
if (-not (Test-Path $ScriptPath)) {
    Write-Host "Script path does not exist: $ScriptPath"
    exit 1
}

# Elevate to SYSTEM and execute the script in an interactive console
try {
    . "$PSScriptRoot\..\..\opt\pstools\PsExec.exe" -s -i $pwsh -ExecutionPolicy Bypass -File $ScriptPath | Out-Null
} catch {
    Write-Host "Failed to execute script: $_"
    exit 1
}
