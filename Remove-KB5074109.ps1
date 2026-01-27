<#
.SYNOPSIS
Uninstalls Windows Update KB5074109 from all computers without forcing a reboot.

.DESCRIPTION
This script removes the KB5074109 Windows update from the system using DISM
and configures the system to not automatically restart after the uninstallation.
Automatically accepts all prompts without user interaction.

.PARAMETER ComputerName
Optional. Specify a list of computer names to target. If not specified, targets local computer.

.PARAMETER NoRestart
When specified, prevents automatic restart after update removal. (Default behavior)

.EXAMPLE
.\Remove-KB5074109.ps1
Uninstalls KB5074109 from the local computer without restarting or prompts.

.EXAMPLE
.\Remove-KB5074109.ps1 -ComputerName "PC1", "PC2"
Uninstalls KB5074109 from PC1 and PC2 without restarting or prompts.

.NOTES
Requires administrator privileges to run.
#>

param(
    [string[]]$ComputerName = @($env:COMPUTERNAME),
    [switch]$NoRestart = $true
)

function Remove-KBUpdate {
    param(
        [string]$KB = "KB5074109",
        [bool]$PreventRestart = $true
    )

    try {
        Write-Host "Starting removal of $KB..." -ForegroundColor Cyan
        
        # Check if update is installed
        $updateInfo = Get-HotFix -Id $KB -ErrorAction SilentlyContinue
        
        if ($updateInfo) {
            Write-Host "Found update: $($updateInfo.Description)" -ForegroundColor Green
            
            # Method 1: Use DISM with /quiet flag to accept all prompts
            Write-Host "Uninstalling $KB using DISM (quiet mode)..." -ForegroundColor Yellow
            $dismResult = & dism.exe /online /remove-package /packagename:Package_for_$KB~31bf3856ad364e35~amd64~~ /norestart /quiet
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "$KB uninstalled successfully without prompts!" -ForegroundColor Green
            }
            elseif ($LASTEXITCODE -eq 3010) {
                Write-Host "$KB uninstalled successfully! Restart required but suppressed." -ForegroundColor Green
            }
            elseif ($LASTEXITCODE -eq 1605) {
                Write-Host "$KB is not installed on this system." -ForegroundColor Yellow
            }
            else {
                # Try alternative method using WUSA
                Write-Host "DISM exit code: $LASTEXITCODE. Trying WUSA method..." -ForegroundColor Yellow
                
                # Extract KB number (remove "KB" prefix)
                $kbNumber = $KB -replace "KB", ""
                
                # Use WUSA with /quiet and /norestart flags
                Write-Host "Uninstalling $KB using WUSA (quiet mode)..." -ForegroundColor Yellow
                Start-Process -FilePath "wusa.exe" -ArgumentList "/uninstall /kb:$kbNumber /quiet /norestart" -Wait -NoNewWindow
                
                if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq 3010) {
                    Write-Host "$KB uninstalled successfully without prompts!" -ForegroundColor Green
                }
                else {
                    Write-Host "WUSA exit code: $LASTEXITCODE" -ForegroundColor Yellow
                }
            }
            
            # Prevent automatic restart
            if ($PreventRestart) {
                Write-Host "Configuring system to prevent automatic restart..." -ForegroundColor Yellow
                reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoRebootWithLoggedOnUsers" /t REG_DWORD /d 1 /f | Out-Null
                reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "AUOptions" /t REG_DWORD /d 2 /f | Out-Null
                Write-Host "Automatic restart disabled." -ForegroundColor Green
            }
        }
        else {
            Write-Host "$KB not found on this system. Already removed or not installed." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Main execution
foreach ($computer in $ComputerName) {
    Write-Host "`n========================================" -ForegroundColor Magenta
    Write-Host "Processing computer: $computer" -ForegroundColor Magenta
    Write-Host "========================================`n" -ForegroundColor Magenta
    
    if ($computer -eq $env:COMPUTERNAME) {
        Remove-KBUpdate -KB "KB5074109" -PreventRestart $NoRestart
    }
    else {
        # For remote computers, use Invoke-Command
        try {
            Invoke-Command -ComputerName $computer -ScriptBlock ${function:Remove-KBUpdate} -ArgumentList "KB5074109", $NoRestart
        }
        catch {
            Write-Host "Failed to connect to $computer : $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Script execution completed!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green
