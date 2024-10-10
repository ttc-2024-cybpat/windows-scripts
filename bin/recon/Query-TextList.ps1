param (
    [string]$Name,
    [string]$Noun = "strings"
)

$comment = "# This file contains a list of {0}.\nPlease paste in the list separated by newlines and save the file." -f $Noun
$dbPath = Join-Path $PSScriptRoot "..\..\data\${Name}.db"

$mustWrite = $false
$checked = $false

# Check if file exists
if (-not (Test-Path $dbPath)) {
    New-Item -Path $dbPath -ItemType File -Force > $null
    Set-Content -Path $dbPath -Value $comment
    $mustWrite = $true
}
else {
    # Read contents, parse into a list
    $contents = Get-Content $dbPath | Where-Object { $_ -notmatch "^#" -and $_ -notmatch "^\s*$" }

    # List out the contents
    Write-Host "Current list of ${Noun}: " -ForegroundColor Magenta -NoNewline
    Write-Host ($contents ?? "<empty>")

    # Ask if OK
    Write-Host "Is this correct? [Y/n] " -ForegroundColor Yellow -NoNewline
    $checked = $true

    $response = Read-Host
    $mustWrite = $response -match "^[Nn]"
}

# Open file for editing
if ($mustWrite) {
    Write-Host "Please check Notepad to configure $Noun." -ForegroundColor Yellow
    Start-Process Notepad.exe $dbPath -NoNewWindow -Wait
}

# Parse into a list and return to caller
$list = Get-Content $dbPath | Where-Object { $_ -notmatch "^#" -and $_ -notmatch "^\s*$" }

if (-not $checked) {
    Write-Host "Current list of ${Noun}: " -ForegroundColor Magenta -NoNewline
    Write-Host ($list ?? "<empty>")
}

# Return the list
Write-Output $list