# Function to modify Firefox shortcuts to also launch Brave
function Add-BraveToFirefox {
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

        # Get the shortcut
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($ShortcutPath)
        
        # Store original Firefox settings
        $firefoxPath = $shortcut.TargetPath
        $firefoxArgs = $shortcut.Arguments
        $firefoxWorkingDir = $shortcut.WorkingDirectory
        
        # Create a simple batch file that will launch both browsers
        $launcherContent = @"
@echo off
start "" "$BravePath"
start "" "$firefoxPath" $firefoxArgs
"@
        $launcherPath = "$env:TEMP\launch_browsers.cmd"
        $launcherContent | Out-File -FilePath $launcherPath -Encoding ASCII
        
        # Modify the shortcut to use our launcher
        $shortcut.TargetPath = $launcherPath
        $shortcut.Arguments = ""
        $shortcut.WorkingDirectory = $firefoxWorkingDir
        
        # Save the changes
        $shortcut.Save()
        
        Write-Host "Successfully modified: $ShortcutPath"
        Write-Host "Will now launch both Firefox and Brave"
        
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
        Add-BraveToFirefox -ShortcutPath $shortcutPath
    }
}

Write-Host "`nCompleted checking all user-level shortcuts."