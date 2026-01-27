# Remove-KB5074109.ps1

# This script uninstalls Windows update KB5074109 from all computers and prevents automatic reboot afterwards.

# Set the Windows Update KB to uninstall
$kb = "KB5074109"

# Uninstall the specified KB
Get-WmiObject -Query "SELECT * FROM Win32_QuickFixEngineering WHERE HotFixID = '$kb'" | ForEach-Object {
    # Uninstall the update
    Write-Host "Uninstalling $kb";
    Start-Process -FilePath "wusa.exe" -ArgumentList "/uninstall /kb:$($kb.Substring(2)) /norestart" -Wait;
}

# Prevent automatic reboot
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Reliability\ReliabilityMonitoring' -Name 'LastRebootReason' -Value 0
Write-Host "Automatic reboot prevented after uninstalling $kb"