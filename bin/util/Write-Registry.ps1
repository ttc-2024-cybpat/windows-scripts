# Force write to registry

param (
    [string]$Key,
    [string]$ValueName,
    [string]$Value,
    [string]$Type
)

# get hive
$parts = $Key -split "\\"
$hive = $parts[0]
$rest = $parts[1..($parts.Length - 1)] -join "\"

# convert hive
switch ($hive) {
    "HKCR" { $hive = [Microsoft.Win32.RegistryHive]::ClassesRoot }
    "HKCU" { $hive = [Microsoft.Win32.RegistryHive]::CurrentUser }
    "HKLM" { $hive = [Microsoft.Win32.RegistryHive]::LocalMachine }
    "HKU"  { $hive = [Microsoft.Win32.RegistryHive]::Users }
    "HKCC" { $hive = [Microsoft.Win32.RegistryHive]::CurrentConfig }
    default { Write-Error "Invalid hive: $hive"; exit 1 }
}

# open hive
$hiveKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey($hive, [Microsoft.Win32.RegistryView]::Default)

# create subkey idc if its already there or not just fucking do it
$key = $hiveKey.CreateSubKey($rest, [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree)
[Microsoft.Win32.Registry]::SetValue($key, $ValueName, $Value, [Microsoft.Win32.RegistryValueKind]::$Type)

# Close the key to release resources
$hiveKey.Close()
