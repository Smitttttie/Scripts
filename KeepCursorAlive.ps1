<#
Script Name: KeepCursorAlive.ps1
Description: 
This script prevents the system from going idle by simulating slight mouse movement.
It moves the cursor 1 pixel to the right and back to its original position every 4 minutes,
making the system think the user is active (avoids lock screen, screensaver, or "away" status).
#>

# Load the Windows Forms assembly to access cursor (mouse) control
Add-Type -AssemblyName System.Windows.Forms

# Start an infinite loop (runs until manually stopped)
while ($true) {
    
    # Get the current mouse cursor position (X and Y coordinates)
    $p = [System.Windows.Forms.Cursor]::Position

    # Move the mouse 1 pixel to the right (simulates activity)
    [System.Windows.Forms.Cursor]::Position = "$($p.X + 1),$($p.Y)"

    # Wait briefly (0.4 seconds) so the movement registers
    Start-Sleep -Milliseconds 400

    # Move the mouse back to its original position
    [System.Windows.Forms.Cursor]::Position = "$($p.X),$($p.Y)"

    # Wait 1 minute (60 seconds) before repeating the process
    Start-Sleep -Seconds 60
}