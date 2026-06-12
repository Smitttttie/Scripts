# Generates periodic simulated keyboard input to maintain active session state and prevent idle-triggered timeouts in Windows environments.

# Create a Windows Script Host (WSH) shell object
# This allows us to send keystrokes to the system
$wsh = New-Object -ComObject WScript.Shell

# Start an infinite loop that will run until manually stopped
while ($true) {
    
    # Send the F15 key press (a non-standard key that usually does nothing)
    # This simulates user activity without interfering with normal work
    $wsh.SendKeys('{F15}')
    
    # Pause the script for 60 seconds (1 minute)
    # This prevents constant key spamming and mimics periodic activity
    Start-Sleep -Seconds 60
}