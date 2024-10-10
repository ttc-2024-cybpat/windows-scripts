$url = "https://download.sysinternals.com/files/PSTools.zip"

function New-Temp {
    $tmp = [System.IO.Path]::GetTempPath()
    $name = (New-Guid).ToString("N")
    New-Item -ItemType Directory -Path (Join-Path $tmp $name)
}

$wc = New-Object Net.WebClient
$tempPath = New-Temp
$wc.DownloadFile($url, "$tempPath\PSTools.zip")

$outPath = "$PSScriptRoot\..\..\opt\pstools"
Expand-Archive -Path "$tempPath\PSTools.zip" -DestinationPath $outPath

# Clean up
Remove-Item -Path $tempPath -Recurse -Force