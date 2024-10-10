param (
    [string]$Path
)

try {
    # Export the security policy to the .inf file
    secedit /export /cfg $Path > $null
    Write-Host "Security policy exported successfully to '$Path'."
}
catch {
    Write-Error "An error occurred: $_"
    exit 1
}

# Find all SIDs in the security policy and replace them with their corresponding names
$policy = Get-Content $Path

# Regular expression to match SIDs
$sidPattern = "\*(S-(?:(?:\d+)-)+\d+)"

# Get all SIDs in the security policy
$sids = $policy | Select-String -Pattern $sidPattern -AllMatches | ForEach-Object { 
    $_.Matches | ForEach-Object { $_.Groups[1].Value } 
} | Sort-Object -Unique
$translateMap = @{}

# Replace SIDs with their corresponding names
foreach ($sid in $sids) {
    Write-Host "Humanizing $sid..." -NoNewline

    $name = $null
    try {
        $name = (New-Object Security.Principal.SecurityIdentifier($sid)).Translate([Security.Principal.NTAccount]).Value
        Write-Host "$name" -ForegroundColor Green
    }
    catch {
        $name = $sid
        Write-Host "$name" -ForegroundColor Red
    }

    $translateMap[$sid] = $name
}

# Update the security policy with human-readable security identifiers
foreach ($sid in $translateMap.Keys) {
    $policy = $policy -replace [regex]::Escape("*$sid"), $translateMap[$sid]
}

# Write the updated security policy back to the .inf file
$policy | Set-Content $Path

Write-Host "Security policy updated with human-readable security identifiers."