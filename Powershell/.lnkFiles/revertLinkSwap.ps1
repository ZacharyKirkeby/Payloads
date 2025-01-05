# This simply undoes the work done by "ChangeShortcut.ps1"

# Function to revert Brave shortcuts back to Firefox
function Convert-BraveToFirefox {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ShortcutPath,
        
        # Default Firefox installation paths
        [string]$FirefoxPath = "${env:ProgramFiles}\Mozilla Firefox\firefox.exe"
    )
    
    try {
        # Verify the shortcut exists
        if (-not (Test-Path $ShortcutPath)) {
            Write-Error "Shortcut not found: $ShortcutPath"
            return $false
        }
        
        # Verify Firefox exists
        if (-not (Test-Path $FirefoxPath)) {
            # Try alternate installation path (x86)
            $FirefoxPath = "${env:ProgramFiles(x86)}\Mozilla Firefox\firefox.exe"
            if (-not (Test-Path $FirefoxPath)) {
                Write-Error "Firefox not found. Please verify it's installed."
                return $false
            }
        }
        
        # Create a WScript Shell object
        $shell = New-Object -ComObject WScript.Shell
        
        # Get the shortcut
        $shortcut = $shell.CreateShortcut($ShortcutPath)
        
        # Store original values for logging
        $originalTarget = $shortcut.TargetPath
        
        # Only modify if it's currently pointing to Brave
        if ($originalTarget -like "*brave.exe") {
            # Modify the shortcut properties
            $shortcut.TargetPath = $FirefoxPath
            $shortcut.WorkingDirectory = (Split-Path $FirefoxPath -Parent)
            $shortcut.IconLocation = "$FirefoxPath,0"
            
            # Save the changes
            $shortcut.Save()
            
            Write-Host "Successfully reverted: $ShortcutPath"
            Write-Host "Original Target: $originalTarget"
            Write-Host "New Target: $FirefoxPath"
        } else {
            Write-Host "Skipping $ShortcutPath - not a Brave shortcut"
        }
        
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

# Check user-specific locations
$userShortcutLocations = @(
    "$env:USERPROFILE\Desktop\Firefox.lnk",
    "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Firefox.lnk",
    "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Firefox.lnk",
    "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\Firefox.lnk"
)

# Try to revert all modified shortcuts
foreach ($shortcutPath in $userShortcutLocations) {
    if (Test-Path $shortcutPath) {
        Write-Host "Found shortcut at: $shortcutPath"
        Convert-BraveToFirefox -ShortcutPath $shortcutPath
    }
}

Write-Host "`nCompleted checking all user-level shortcuts."