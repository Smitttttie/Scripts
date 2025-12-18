# Script: Add MS Office Shortcuts to All User Desktops
# Run this script with Administrator privileges.

# Define the applications and their paths
$apps = @(
    @{ Name = "Outlook";   Target = "C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE" },
    @{ Name = "PowerPoint"; Target = "C:\Program Files\Microsoft Office\root\Office16\POWERPNT.EXE" },
    @{ Name = "Excel";     Target = "C:\Program Files\Microsoft Office\root\Office16\EXCEL.EXE" },
    @{ Name = "Teams";     Target = "C:\Program Files\Microsoft Teams\current\Teams.exe" },
    @{ Name = "OneNote";   Target = "C:\Program Files\Microsoft Office\root\Office16\ONENOTE.EXE" },
    @{ Name = "Word";      Target = "C:\Program Files\Microsoft Office\root\Office16\WINWORD.EXE" }
)

# Get all user Desktop directories (excluding system/default accounts)
$users = Get-ChildItem "C:\Users" | Where-Object { 
    $_.PSIsContainer -and
    $_.Name -notin @("Default", "Public", "All Users", "defaultuser0", "Administrator")
}

foreach ($user in $users) {
    $desktopPath = Join-Path $user.FullName 'Desktop'
    if (-Not (Test-Path $desktopPath)) { continue }

    foreach ($app in $apps) {
        $target = $app.Target
        if (-Not (Test-Path $target)) { continue }

        # Create the shortcut
        $WshShell = New-Object -ComObject WScript.Shell
        $shortcut = $WshShell.CreateShortcut("$desktopPath\$($app.Name).lnk")
        $shortcut.TargetPath = $target
        $shortcut.Save()
    }
}

Write-Host "Shortcuts have been added to all user desktops."