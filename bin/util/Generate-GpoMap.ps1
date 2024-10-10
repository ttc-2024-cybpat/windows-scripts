# Raw GPO map in XLSX format can be downloaded at:
# https://www.microsoft.com/en-us/download/details.aspx?id=25250

# Convert XLSX file to CSV using LibreOffice and pass it to this script

param (
    [string]$Path,
    [string]$OutPath = "gpomap.csv"
)

# Load CSV file into memory
$csv = Import-Csv -Path $Path

# Filter out the columns we need: "Policy Setting Name", "Policy Path", "Registry Information"
# Rename "Policy Path" to "Path" and "Registry Information" to "Registry"
$filteredCsv = $csv | Select-Object @{Name='Path';Expression={$_."Policy Path"}},
                                    @{Name='Key';Expression={$_."Registry Information"}},
                                    @{Name='Policy';Expression={$_."Policy Setting Name"}}

# Append "Policy Setting Name" to the "Path" column and remove the "Policy Setting Name" column
$modifiedCsv = $filteredCsv | ForEach-Object {
    $_.Path = $_.Path + "\" + $_.Policy
    $_ | Select-Object -ExcludeProperty Policy
}

# Pull the value from "Key" and add to a new column "Value"
# Split by "!" and take the last element for the value, then replace Key with the first element
$modifiedCsv = $modifiedCsv | ForEach-Object {
    $key = $_.Key -split "!"
    
    # Create a new object to hold the modified properties
    $newObject = [PSCustomObject]@{
        Path  = $_.Path
        Key   = $key[0] # ($key[0] -replace "(.*?)\\(.*)", '$1:$2') # Replace the first backslash with a colon
        Value = ($key[1] -split " ")[0] # Use the last element or null
    }
    
    $newObject  # Return the new object
}

# Export to CSV
$modifiedCsv | Export-Csv -Path $OutPath -NoTypeInformation