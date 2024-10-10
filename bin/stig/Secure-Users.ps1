# V-220712

# Identify current user, split by slash and select the last element
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name -split '\\' | Select-Object -Last 1

# Query users and administrators, filter out the current user
$authUsers = . "$PSScriptRoot\..\recon\Query-TextList.ps1" -Name "authusers" -Noun "authorized users" |
    Where-Object { $_ -ne $currentUser }
$authAdmins = . "$PSScriptRoot\..\recon\Query-TextList.ps1" -Name "authadmins" -Noun "authorized administrators" |
    Where-Object { $_ -ne $currentUser }

# List out built-in accounts
$builtinUsers = @("Administrator", "Guest", "DefaultAccount", "WDAGUtilityAccount", "defaultuser0")

# Get all users on the system but filter out authUsers, authAdmins, and currentUser, and builtin accounts
$unauthorizedUsers = Get-LocalUser | Where-Object { 
    ($authUsers -notcontains $_.Name) -and 
    ($authAdmins -notcontains $_.Name) -and 
    ($_.Name -ne $currentUser) -and 
    ($builtinUsers -notcontains $_.Name)
}

# List everything
Write-Host "Authorized Users:   " -ForegroundColor Magenta -NoNewline
Write-Host ($authUsers ?? "<empty>")

Write-Host "Authorized Admins:  " -ForegroundColor Magenta -NoNewline
Write-Host ($authAdmins ?? "<empty>")

Write-Host "Unauthorized Users: " -ForegroundColor Magenta -NoNewline
Write-Host ($unauthorizedUsers ?? "<empty>")

# Continue y/N
Write-Host "Is this correct? [y/N] " -ForegroundColor Yellow -NoNewline
$response = Read-Host
if ($response -notmatch "^[Yy]") {
    Write-Host "Exiting..." -ForegroundColor Red
    exit 1
}

# Remove user from unauthorized groups
function Reset-LocalUserGroups {
    param (
        [string]$Name,
        [string[]]$ExpectedGroups
    )

    try {
        # Fetch all groups the user is a member of
        $userGroups = @()

        foreach ($group in Get-LocalGroup) {
            $members = Get-LocalGroupMember -Group $group.Name
            if ($members -contains $Name) { # fuck you microsoft god fucking damn it
                $userGroups += $group
            }
        }

        # Check each group to see if it's expected, and remove if not
        foreach ($group in $userGroups) {
            if ($ExpectedGroups -notcontains $group.Name) {
                Write-Host "Removing $Name from group $($group.Name)"
                try {
                    Remove-LocalGroupMember -Group $group.Name -Member $Name
                }
                catch {
                    Write-Error "Error occurred: $_"
                }
            }
        }
    }
    catch {
        Write-Error "Error occurred: $_"
    }
}

# Reset password of a local user account along with some properties
function Reset-LocalUserPassword {
    param (
        [string]$Name  # Name of the user account to reset
    )

    try {
        # Generate a password using Generate-Password.ps1
        $password = . "$PSScriptRoot\..\util\Generate-Password.ps1"

        # Write user:pass combo to a file (in plain text as per company policy)
        $passwordEntry = "${Name}:${password}"
        Add-Content -Path "$PSScriptRoot\..\..\data\passwords.db" -Value $passwordEntry

        # Set password for the user account and configure properties
        try {
            Write-Host "Changing password for $Name and set pw props"
            Set-LocalUser -Name $Name `
                -Password (ConvertTo-SecureString -String $password -AsPlainText -Force) `
                -PasswordNeverExpires $false `
                -UserMayChangePassword $true
        }
        catch {
            Write-Error "Error occurred: $_"
        }

        # Force password expiration (user must change password at next logon)
        try {
            Write-Host "Forcing password expiration for $Name"
            $user = [ADSI]"WinNT://$env:ComputerName/${Name},user"
            $user.PasswordExpired = 1
            $user.SetInfo()
        }
        catch {
            Write-Error "Error occurred: $_"
        }
    }
    catch {
        Write-Error "Error occurred: $_"
    }
}

# For all users, secure them
foreach ($user in $authUsers) {
    Reset-LocalUserGroups -Name $user -ExpectedGroups @("Users")
    Reset-LocalUserPassword -Name $user
}

# For all administrators, secure them
foreach ($admin in $authAdmins) {
    Reset-LocalUserGroups -Name $admin -ExpectedGroups @("Administrators")
    Reset-LocalUserPassword -Name $admin
}

# We typically want to disable Administrator and Guest
$builtinUsersToDisable = @("Administrator", "Guest", "DefaultAccount")

# Disable all unauthorized users.
foreach ($user in $unauthorizedUsers + $builtinUsersToDisable) {
    Write-Host "Disabling user $($user)"
    try {
        Disable-LocalUser -Name $user
    }
    catch {
        Write-Error "Error occurred: $_"
    }
}
