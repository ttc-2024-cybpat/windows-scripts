# Export the groups on the system to a file
param (
    [string]$outputPath
)

# Get all groups on the system
$groups = Get-LocalGroup

# Export groups to CSV
$groups | Select-Object -Property Name | Export-Csv -Path $outputPath -NoTypeInformation