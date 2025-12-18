# Shortcuts to check
$shortcuts = @("Outlook.lnk", "PowerPoint.lnk", "Excel.lnk", "Teams.lnk", "OneNote.lnk", "Word.lnk")

# Get all user profile directories excluding system/default accounts
$users = Get-ChildItem "C:\Users" | Where-Object { 
    $_.PSIsContainer -and
    $_.Name -notin @("Default", "Public", "All Users", "defaultuser0", "Administrator")
}

# Flag to track if all shortcuts exist
$allShortcutsFound = $true

# Loop through all shortcuts and verify if each exists on any user's desktop
foreach ($shortcut in $shortcuts) {
    $shortcutFound = $false
    
    foreach ($user in $users) {
        $desktopPath = Join-Path $user.FullName "Desktop"
        if (Test-Path (Join-Path $desktopPath $shortcut)) {
            $shortcutFound = $true
            break
        }
    }

    if (-not $shortcutFound) {
        $allShortcutsFound = $false
        break
    }
}

# Exit code: 0 if all shortcuts are found, 1 if any shortcut is missing
if ($allShortcutsFound) {
    exit 0  # All shortcuts found, app is detected
} else {
    exit 1  # One or more shortcuts missing, app is not detected
}