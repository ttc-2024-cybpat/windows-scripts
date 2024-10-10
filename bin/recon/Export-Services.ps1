# Export all services on the system to a file (in an xml format)
param(
    [string]$outputPath
)

# Export the services to a a file in CSV format, only name and start type
Get-Service | Select-Object -Property Name, StartType | Export-Csv -Path $outputPath -NoTypeInformation