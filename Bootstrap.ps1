$repo = "ttc-2024-cybpat/windows-scripts"
$branch = "main"

# Repository name only
$repoName = $repo.Split("/")[1]

# Set up execution policy
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# Init web client
$wc = New-Object System.Net.WebClient
$wc.Headers.Add("Cache-Control", "no-cache")

# It might be odd using HTTP here, but we're not really transferring sensitive data
# Also I've had instances where TLS just refuses to work in CyberPatriot and OKCup

# Check if admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # Restart with runas; download this script to a temp path and restart
    $script = "http://github.com/$repo/raw/$branch/Bootstrap.ps1"
    $scriptPath = [System.IO.Path]::Combine($env:TEMP, (New-Guid).ToString("N") + ".ps1")

    Write-Host "Restarting with elevated privileges..." -ForegroundColor Yellow
    $wc.DownloadFile($script, $scriptPath)

    Start-Process -FilePath "powershell.exe" -ArgumentList "-File $scriptPath" -Verb RunAs
    exit 1
}

# Create zip paths
$zipPath = [System.IO.Path]::Combine($env:TEMP, (New-Guid).ToString("N") + ".zip")
$outPath = [System.IO.Path]::Combine([System.Environment]::GetFolderPath("Desktop"), "cybpat-scripts")
$tempOut = [System.IO.Path]::Combine($env:TEMP, (New-Guid).ToString("N"))

# Delete outPath if it exists
if (Test-Path $outPath) {
    Remove-Item -Path $outPath -Recurse -Force
}

# Pull zip file straight from GitHub
try {
    Write-Host "Downloading latest scripts from GitHub..."
    $wc.DownloadFile("http://github.com/$repo/archive/refs/heads/$branch.zip", $zipPath)
}
catch {
    Write-Host "Failed to download scripts from GitHub." -ForegroundColor Red
    Read-Host "Press any key to continue..."
    exit 1
}

# Unzip the file
try {
    Write-Host "Unzipping to $outPath..."
    Expand-Archive -Path $tempOut -DestinationPath [System.Environment]::GetFolderPath("Desktop")
}
catch {
    Write-Host "Failed to unzip scripts." -ForegroundColor Red
    Read-Host "Press any key to continue..."
    exit 1
}

# Move the contents to the desktop
Move-Item -Path "$tempOut\$repoName-$branch" -Destination $outPath -Force

# Clean up
Write-Host "Deleting zip file..."
Remove-Item -Path $zipPath -Force
Remove-Item -Path $tempOut -Recurse -Force

# Check for existing PowerShell 7
if (-not (Get-Command pwsh.exe -ErrorAction SilentlyContinue)) {
    # Download PowerShell
    $ps7Path = [System.IO.Path]::Combine($env:TEMP, (New-Guid).ToString("N") + ".msi")
    try {
        # Determine PowerShell type to download
        $arch = if ([System.Environment]::Is64BitOperatingSystem) { "win-x64" } else { "win-x86" }
        $url = "http://github.com/PowerShell/PowerShell/releases/download/v7.4.5/PowerShell-7.4.5-$arch.msi"

        # Download the installer
        Write-Host "Downloading PowerShell 7 $arch installer..."
        $wc.DownloadFile($url, $ps7Path)
    }
    catch {
        Write-Host "Failed to download PowerShell 7 installer." -ForegroundColor Red
        Read-Host "Press any key to continue..."
        exit 1
    }

    # Install PowerShell 7
    Write-Host "Installing PowerShell 7..."
    Start-Process msiexec -ArgumentList "/package $ps7Path /quiet ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ADD_FILE_CONTEXT_MENU_RUNPOWERSHELL=1 ENABLE_PSREMOTING=1 REGISTER_MANIFEST=1 USE_MU=1 ENABLE_MU=1 ADD_PATH=1" -Wait

    # Clean up
    Write-Host "Deleting PowerShell 7 installer..."
    Remove-Item -Path $ps7Path -Force

    # Update PATH for this process since it doesn't update automatically
    $currentPath = [System.Environment]::GetEnvironmentVariable("Path")
    [System.Environment]::SetEnvironmentVariable("Path", "$currentPath;C:\Program Files\PowerShell\7;C:\Program Files (x86)\PowerShell\7")
}

# Run PowerShell 7 in the new directory
Write-Host "Spawning PowerShell..."

$targetPowershell = "pwsh.exe"
if (-not (Get-Command $targetPowershell -ErrorAction SilentlyContinue)) {
    Write-Host "PowerShell 7 not found. Fallback to default PowerShell." -ForegroundColor Red
    $targetPowershell = "powershell.exe"
}

Start-Process $targetPowershell -WorkingDirectory $outPath
