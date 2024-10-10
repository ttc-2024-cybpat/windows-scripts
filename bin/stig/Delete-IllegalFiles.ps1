# Delete unauthorized files from the system

if ((whoami) -ne "NT AUTHORITY\SYSTEM") {
    Write-Host "Elevating to NT AUTHORITY\SYSTEM..."
    . "$PSScriptRoot\..\util\RunAs-System.ps1" -ScriptPath $MyInvocation.MyCommand.Path
    exit 0
}

$origPasswords = . "$PSScriptRoot\..\recon\Query-TextList.ps1" -Name "origpasswd" -Noun "original passwords" |
    Where-Object { $_ -ne $currentUser }

# Generate regex for original passwords
$origPasswords = ($origPasswords | ForEach-Object { [regex]::Escape($_) }) -join "|"

$multimediaExtensions = @(
    ".mp4",
    ".mkv",
    ".avi",
    ".mov",
    ".wmv",
    ".flv",
    ".webm",
    ".mpeg",
    ".mpg",
    ".3gp",
    ".m4v",
    ".rm",
    ".ogg"
)

$audioExtensions = @(
    ".mp3",
    ".wav",
    ".aac",
    ".ogg",
    ".wma",
    ".flac",
    ".m4a",
    ".aiff",
    ".aif",
    ".mid",
    ".midi",
    ".opus",
    ".dsf",
    ".dff",
    ".cda",
    ".wv"
)

$imageExtensions = @(
    ".jpg",
    ".jpeg",
    ".png",
    ".gif",
    ".bmp",
    ".tiff",
    ".tif",
    ".svg",
    ".webp",
    ".raw",
    ".ico",
    ".heic",
    ".indd",
    ".ai",
    ".eps"
)

# Check for a cache database
if (-not (Test-Path "$PSScriptRoot\..\..\data\index.db")) {
    # Deep inspect all files on the system
    Write-Host "Creating an index cache of all files. This may take a while..."
    
    # Define the cache path
    $cachePath = Join-Path $PSScriptRoot "..\..\data\index.db"

    # Use a StreamWriter to write directly to the file
    $stream = [System.IO.StreamWriter]::new($cachePath, $false)

    # Counter
    $counter = 0
    $notifyEach = 1500

    try {
        # Get all files recursively and process them in batches
        Get-ChildItem -Path "C:\Users" -Recurse -File | ForEach-Object {
            # Write each file path to the cache directly
            $stream.WriteLine($_.FullName)

            # Notify
            if (++$counter % $notifyEach -eq 0) {
                # Clear line
                [System.Console]::SetCursorPosition(0, [System.Console]::CursorTop)

                # Write the counter
                Write-Host "$counter..." -NoNewline
            }
        }
    }
    finally {
        # Ensure the StreamWriter is closed properly
        $stream.Close()
    }

    Write-Host "`n" -NoNewline
}

$indexCache = Join-Path $PSScriptRoot "..\..\data\index.db"

# Read the cache database line by line
Write-Host "Checking for unauthorized extensions..."
$counter = 0
$notifyEach = 1000

Get-Content -Path $indexCache | ForEach-Object {
    # Check multimedia, audio, and image extensions
    $ext = [System.IO.Path]::GetExtension($_).ToLower()
    if ($multimediaExtensions -contains $ext -or $audioExtensions -contains $ext -or $imageExtensions -contains $ext) {
        Write-Host "`nFound unauthorized file: $_. Deleted."
        Remove-Item $_ -Force
    }

    if (++$counter % $notifyEach -eq 0) {
        # Clear line
        [System.Console]::SetCursorPosition(0, [System.Console]::CursorTop)

        # Write the counter
        Write-Host "$counter..." -NoNewline
    }
}

Write-Host "`n" -NoNewline

# Deep inspection of all user files
Write-Host "Conducting a deep inspection of all files under 'Users'. This may take a while..."
$counter = 0
$notifyEach = 500

Get-Content -Path $indexCache | ForEach-Object {
    # Check for illegal content
    try {
        $file = Get-Item $_ -ErrorAction SilentlyContinue

        # Do not scan files outside of C:\Users
        #if ($file.DirectoryName -notmatch "C:\\Users") {
        #    return
        #}

        # Extension
        $ext = [System.IO.Path]::GetExtension($file.FullName).ToLower()

        # Check in text-based files
        if ($ext -eq ".txt" -or $ext -eq ".log" -or $ext -eq ".csv" -or $ext -eq ".xml" -or $ext -eq ".json") {
            # Check title for illegal content
            if ($file.Name -match "(?i)passwords?" -or $file.Name -match "(?i)secrets?" -or $file.Name -match "(?i)credentials?") {
                Write-Host "`nFound a password-related file: $_"
            }

            $content = Get-Content $file -Raw -ErrorAction SilentlyContinue

            # Match a password on the system
            if ($content -match $origPasswords) {
                Write-Host "`nFound an original password in $_"
            }

            # Match social security terms
            if ($content -match "\b\d{3}[- ]\d{2}[- ]\d{4}\b" -or $content -match "(?i)social ?security") {
                Write-Host "`nFound social security terms in $_"
            }

            # Match credit card terms
            # way too many false positives
            #if ($content -match "(?i)credit ?card" -or $content -match "(?i)cc ?(number|#)" -or $content -match "(?i)card ?holder" -or $content -match "(?i)expiration ?date" -or $content -match "(?i)security ?code" -or $content -match "(?i)visa" -or $content -match "(?i)mastercard") {
            #    Write-Host "`nFound credit card terms in $_"
            #}
        }
    }
    catch {
        # Expected for some files
    }

    if (++$counter % $notifyEach -eq 0) {
        # Clear line
        [System.Console]::SetCursorPosition(0, [System.Console]::CursorTop)

        # Write the counter
        Write-Host "$counter..." -NoNewline
    }
}

Write-Host "`n" -NoNewline

pause
