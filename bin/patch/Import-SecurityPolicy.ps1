param(
    [string]$Path
)

# Check if the .inf file exists
if (-not (Test-Path $Path)) {
    Write-Error "The specified .inf file at $Path does not exist."
    exit 1
}

try {
    # Apply security policy using secedit
    secedit /configure /db C:\Windows\security\Database\secedit.sdb /cfg $Path /overwrite
    if ($LASTEXITCODE -ne 0) {
        throw "Secedit command failed with exit code $LASTEXITCODE."
    }

    Write-Host "Security policy applied successfully."
} catch {
    Write-Error "An error occurred: $_"
    exit 1
}
