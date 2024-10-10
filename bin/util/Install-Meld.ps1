$url = "https://download.gnome.org/binaries/win32/meld/3.22/Meld-3.22.2-mingw.msi"

function New-Temp {
    $tmp = [System.IO.Path]::GetTempPath()
    $name = (New-Guid).ToString("N")
    New-Item -ItemType Directory -Path (Join-Path $tmp $name)
}

# I love using .NET in PowerShell
$wc = New-Object Net.WebClient
$wc.DownloadFile($url, "$tempPath/.msi")
$wc.Dispose()

Start-Process msiexec -ArgumentList "/i $tempPath\.msi /quiet" -Wait
Write-Host "Meld installed successfully"

# Clean up
Remove-Item -Path $tempPath -Recurse -Force
exit 0