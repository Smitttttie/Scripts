# Diagnose-KB5074109.ps1

# This PowerShell script helps diagnose why the removal of KB5074109 failed.

# Function to check if the update is installed
function Check-UpdateInstalled {
    param(
        [string]$UpdateID
    )
    $installedUpdates = Get-WindowsUpdateLog | Select-String -Pattern $UpdateID
    return $installedUpdates -ne $null
}

# Function to check system logs for errors
function Check-SystemLogs {
    Get-EventLog -LogName System -EntryType Error -Newest 20
}

# Function to check Windows Update status
function Check-WindowsUpdateStatus {
    Get-Service -Name wuauserv | Select-Object Status
}

# Function to provide detailed error information
function Get-ErrorInformation {
    param(
        [string]$UpdateID
    )
    $errorInfo = Get-WindowsUpdateLog | Select-String -Pattern $UpdateID
    return $errorInfo
}

# Main function to diagnose KB5074109 removal failure
function Diagnose-KB5074109 {
    $updateID = "KB5074109"
    
    # Check if the update is installed
    if (Check-UpdateInstalled $updateID) {
        Write-Output "Update $updateID is installed."
    } else {
        Write-Output "Update $updateID is not installed."
    }
    
    # Check system logs
    Write-Output "Checking system logs..."
    Check-SystemLogs
    
    # Check Windows Update status
    Write-Output "Checking Windows Update status..."
    Check-WindowsUpdateStatus
    
    # Provide detailed error information
    Write-Output "Getting error information for $updateID..."
    Get-ErrorInformation $updateID
}

# Run the diagnosis
Diagnose-KB5074109