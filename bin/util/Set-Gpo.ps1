# Convert group policy path to a registry path

param (
    [string]$Path,
    [string]$Value,
    [string]$Type
)

# Load gpomap.csv from $PSScriptRoot\..\..\static\gpomap.csv
$gpomap = Import-Csv -Path "$PSScriptRoot\..\..\static\gpomap.csv"

# Look up Path in the "Path" column and pull the "Key" and "Value" columns
$cols = $gpomap | Where-Object { $_.Path -eq $Path } | Select-Object "Key", "Value"

# Check if a corresponding registry path was found
if ($null -ne $cols) {
    . "$PSScriptRoot\Write-Registry.ps1" -Key $cols.Key -ValueName $cols.Value -Value $Value -Type $Type
}
else {
    Write-Error "No registry path found for $Path"
    exit 1
}
