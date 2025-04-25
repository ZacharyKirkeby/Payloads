# WiFi Profile Password Retriever in PowerShell

function Check-WindowsOS {
    if ($env:OS -like "*Windows*") {
        return $true
    }
    return $false
}

function Get-WifiProfiles {
    $output = netsh.exe wlan show profiles | Out-String
    $profiles = @()
    $regex = [regex]::new('.*: (.*)')
    $matches = $regex.Matches($output)
    
    foreach ($match in $matches) {
        if ($match.Groups.Count -gt 1) {
            # Remove any trailing whitespace/newline characters
            $profile = $match.Groups[1].Value.Trim()
            $profiles += $profile
        }
    }
    
    return $profiles
}

function Get-WifiPasswords {
    param (
        [Parameter(Mandatory=$true)]
        [array]$Profiles
    )
    
    $keys = @{}
    
    foreach ($profile in $Profiles) {
        $name = "name=$profile"
        $output = netsh.exe wlan show profiles $name key=clear | Out-String
        
        $regex = [regex]::new('Key Content.*: (.*)')
        $matches = $regex.Matches($output)
        
        foreach ($match in $matches) {
            if ($match.Groups.Count -gt 1) {
                # Remove any trailing whitespace/newline characters
                $key = $match.Groups[1].Value.Trim()
                $keys[$profile] = $key
            }
        }
    }
    
    return $keys
}

function Print-ProfileKeys {
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$ProfileKeys
    )
    
    foreach ($profile in $ProfileKeys.Keys) {
        $key = $ProfileKeys[$profile]
        Write-Host "Network Name: $profile `t Password: $key"
    }
}

function Print-AllProfiles {
    param (
        [Parameter(Mandatory=$true)]
        [array]$Profiles
    )
    
    Write-Host "No English terminal detected..."
    Write-Host "Printing all raw data..."
    Start-Sleep -Seconds 1
    
    foreach ($profile in $Profiles) {
        $name = "name=$profile"
        $output = netsh.exe wlan show profiles $name key=clear | Out-String
        Write-Host $output
    }
}
function Main {
    if (Check-WindowsOS) {
        Write-Host "Windows OS detected"
        $profiles = Get-WifiProfiles
        $profileKeys = Get-WifiPasswords -Profiles $profiles
        Write-Host $profileKeys
        Write-Host $profileKeys.Count
        
        if ($profileKeys.Count -ne 0) {
            Print-ProfileKeys -ProfileKeys $profileKeys
        } else {
            Print-AllProfiles -Profiles $profiles
        }
    } else {
        Write-Host "No Windows OS detected"
    }
    
    Write-Host "Press Enter to close..."
    Read-Host
}

# Execute the main function
Main
