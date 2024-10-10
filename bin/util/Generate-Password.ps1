# CIS recommends that a password must:
# - Be at least 14 characters long
# - Contain at least one uppercase letter
# - Contain at least one lowercase letter
# - Contain at least one number
# - Contain at least one special character

# Set up charsets
$lowercase = "abcdefghijklmnopqrstuvwxyz"
$uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
$digit     = "0123456789"
$special   = "!@#$%^&*()_+{}|:<>?~"
$all       = $lowercase + $uppercase + $digit + $special

# Generate 1 random character from each required charset
$pLower   = $lowercase[$(Get-Random -Minimum 0 -Maximum $lowercase.Length)]
$pUpper   = $uppercase[$(Get-Random -Minimum 0 -Maximum $uppercase.Length)]
$pDigit   = $digit[$(Get-Random -Minimum 0 -Maximum $digit.Length)]
$pSpecial = $special[$(Get-Random -Minimum 0 -Maximum $special.Length)]

# Generate 10 random characters from all charsets
$randomChars = 1..10 | ForEach-Object { $all[$(Get-Random -Minimum 0 -Maximum $all.Length)] }

# Combine all characters and shuffle
$passwordChars = @($pLower, $pUpper, $pDigit, $pSpecial) + $randomChars
$password = $passwordChars | Sort-Object {Get-Random}

# Output the password
Write-Output ($password -join "")
