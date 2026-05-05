<#
.SYNOPSIS
Generates a comprehensive versioning storage report for all SharePoint Online sites.

.DESCRIPTION
This script connects to your SharePoint Online tenant and generates detailed reports on the 
storage consumed by file versioning across all sites and libraries.

.PARAMETER TenantAdminUrl
The URL of your SharePoint Online tenant admin site (e.g., https://yourorg-admin.sharepoint.com)

.PARAMETER OutputPath
The directory path where reports will be saved. Defaults to the current user's Downloads folder.

.PARAMETER IncludeOneDrive
Switch to include OneDrive for Business sites in the analysis. Defaults to $false (SharePoint sites only).

.EXAMPLE
.\Get-SharePointVersioningStorageReport.ps1

.EXAMPLE
.\Get-SharePointVersioningStorageReport.ps1 -TenantAdminUrl "https://yourorg-admin.sharepoint.com"

.EXAMPLE
.\Get-SharePointVersioningStorageReport.ps1 -TenantAdminUrl "https://yourorg-admin.sharepoint.com" -OutputPath "C:\Reports" -IncludeOneDrive

.NOTES
Requires PnP.PowerShell module. The script will attempt to install it if not present.
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$TenantAdminUrl,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = $env:USERPROFILE + "\Downloads",

    [Parameter(Mandatory = $false)]
    [switch]$IncludeOneDrive = $false
)

# Ensure output directory exists
if (-not (Test-Path -Path $OutputPath)) {
    Write-Host "Creating output directory: $OutputPath" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

# Check and install PnP.PowerShell if needed
function Ensure-PnPModule {
    $module = Get-Module -Name PnP.PowerShell -ListAvailable
    if (-not $module) {
        Write-Host "PnP.PowerShell module not found. Installing..." -ForegroundColor Yellow
        Install-Module -Name PnP.PowerShell -Force -AllowClobber -Scope CurrentUser
        Write-Host "PnP.PowerShell installed successfully." -ForegroundColor Green
    }
    else {
        Write-Host "PnP.PowerShell module found: Version $($module.Version)" -ForegroundColor Green
    }
    Import-Module -Name PnP.PowerShell -Force
}

# Connect to SharePoint tenant
function Connect-ToSharePoint {
    param(
        [Parameter(Mandatory = $false)]
        [string]$AdminUrl
    )

    if ([string]::IsNullOrEmpty($AdminUrl)) {
        $AdminUrl = Read-Host "Enter your SharePoint Online Tenant Admin URL (e.g., https://yourorg-admin.sharepoint.com)"
    }

    try {
        Write-Host "Connecting to SharePoint Online tenant: $AdminUrl" -ForegroundColor Cyan
        Connect-PnPOnline -Url $AdminUrl -Interactive
        Write-Host "Connected successfully!" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to connect to SharePoint Online: $_" -ForegroundColor Red
        exit 1
    }
}

# Get all SharePoint sites
function Get-AllSharePointSites {
    param(
        [Parameter(Mandatory = $false)]
        [bool]$IncludeOneDrive = $false
    )

    try {
        Write-Host "Retrieving all SharePoint Online sites (OneDrive: $IncludeOneDrive)..." -ForegroundColor Cyan
        $sites = Get-PnPTenantSite -IncludeOneDriveSites $IncludeOneDrive | Where-Object { $_.Status -eq "Active" }
        Write-Host "Found $($sites.Count) active SharePoint sites." -ForegroundColor Green
        return $sites
    }
    catch {
        Write-Host "Failed to retrieve sites: $_" -ForegroundColor Red
        return $null
    }
}

# Calculate versioning storage for a library
function Get-VersioningStorage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SiteUrl,
        
        [Parameter(Mandatory = $true)]
        [string]$LibraryTitle
    )
    
    try {
        $connection = Connect-PnPOnline -Url $SiteUrl -Interactive -ReturnConnection
        $lists = Get-PnPList -Connection $connection | Where-Object { $_.BaseTemplate -in 101, 100 }
        
        $totalVersioningSize = 0
        $libraryDetails = @()
        
        foreach ($list in $lists) {
            $items = Get-PnPListItem -List $list.Id -Connection $connection -PageSize 5000
            $listVersioningSize = 0
            
            foreach ($item in $items) {
                $versions = Get-PnPProperty -ClientObject $item -Property Versions -Connection $connection
                foreach ($version in $versions) {
                    if ($version.Size) {
                        $listVersioningSize += $version.Size
                    }
                }
            }
            
            if ($listVersioningSize -gt 0) {
                $libraryDetails += @{
                    SiteUrl = $SiteUrl
                    LibraryName = $list.Title
                    VersioningStorageBytes = $listVersioningSize
                    VersioningStorageMB = [math]::Round($listVersioningSize / 1MB, 2)
                    VersioningStorageGB = [math]::Round($listVersioningSize / 1GB, 2)
                    ItemCount = $items.Count
                }
                $totalVersioningSize += $listVersioningSize
            }
        }
        
        return @{
            TotalVersioningSize = $totalVersioningSize
            LibraryDetails = $libraryDetails
        }
    }
    catch {
        Write-Host "Error processing site $SiteUrl : $_" -ForegroundColor Yellow
        return @{
            TotalVersioningSize = 0
            LibraryDetails = @()
        }
    }
}

# Main execution
function Main {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "SharePoint Online Versioning Storage Report" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Ensure module is installed
    Ensure-PnPModule

    # Connect to SharePoint
    Connect-ToSharePoint -AdminUrl $TenantAdminUrl

    # Get all sites
    $sites = Get-AllSharePointSites -IncludeOneDrive $IncludeOneDrive
    if (-not $sites) {
        Write-Host "No sites found or error retrieving sites." -ForegroundColor Red
        exit 1
    }
    
    # Generate report data
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $reportPath = Join-Path -Path $OutputPath -ChildPath "SharePoint_Versioning_Report_$timestamp.csv"
    $detailedReportPath = Join-Path -Path $OutputPath -ChildPath "SharePoint_Versioning_Report_$timestamp`_Detailed.csv"
    
    $siteReports = @()
    $allLibraryDetails = @()
    $totalTenantVersioningStorage = 0
    
    $siteCount = $sites.Count
    $currentSite = 0
    
    foreach ($site in $sites) {
        $currentSite++
        $percentComplete = ($currentSite / $siteCount) * 100
        Write-Progress -Activity "Processing Sites" -Status "Site $currentSite of $siteCount" -PercentComplete $percentComplete
        
        Write-Host "Processing site: $($site.Title) ($($site.Url))" -ForegroundColor Cyan
        
        $versioningData = Get-VersioningStorage -SiteUrl $site.Url -LibraryTitle $site.Title
        
        $siteReports += @{
            SiteTitle = $site.Title
            SiteUrl = $site.Url
            StorageUsedGB = [math]::Round($site.StorageUsageCurrent / 1GB, 2)
            VersioningStorageBytes = $versioningData.TotalVersioningSize
            VersioningStorageMB = [math]::Round($versioningData.TotalVersioningSize / 1MB, 2)
            VersioningStorageGB = [math]::Round($versioningData.TotalVersioningSize / 1GB, 2)
            LastModified = $site.LastContentModifiedTime
        }
        
        $allLibraryDetails += $versioningData.LibraryDetails
        $totalTenantVersioningStorage += $versioningData.TotalVersioningSize
    }
    
    Write-Progress -Activity "Processing Sites" -Completed
    
    # Export site-level report
    Write-Host "Exporting site-level report to: $reportPath" -ForegroundColor Yellow
    $siteReports | Select-Object SiteTitle, SiteUrl, StorageUsedGB, VersioningStorageGB, VersioningStorageMB, LastModified | Export-Csv -Path $reportPath -NoTypeInformation -Encoding UTF8
    
    # Export detailed library report
    if ($allLibraryDetails.Count -gt 0) {
        Write-Host "Exporting detailed library report to: $detailedReportPath" -ForegroundColor Yellow
        $allLibraryDetails | Select-Object SiteUrl, LibraryName, VersioningStorageGB, VersioningStorageMB, ItemCount | Export-Csv -Path $detailedReportPath -NoTypeInformation -Encoding UTF8
    }
    
    # Display summary
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Report Summary" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Total Sites Analyzed: $($siteReports.Count)" -ForegroundColor White

    $totalVersioningGB = [math]::Round($totalTenantVersioningStorage / 1GB, 2)
    Write-Host "Total Versioning Storage: $totalVersioningGB GB" -ForegroundColor White

    # Calculate version reduction recommendations
    $reduction50 = [math]::Round($totalVersioningGB * 0.5, 2)
    $reduction75 = [math]::Round($totalVersioningGB * 0.75, 2)

    Write-Host ""
    Write-Host "Version Reduction Estimates:" -ForegroundColor Cyan
    Write-Host "  - Reducing to 50% versions: Save ~$reduction50 GB" -ForegroundColor Yellow
    Write-Host "  - Reducing to 25% versions: Save ~$reduction75 GB" -ForegroundColor Yellow

    Write-Host ""
    Write-Host "Reports Generated:" -ForegroundColor White
    Write-Host "  - Site Report: $reportPath" -ForegroundColor Cyan
    Write-Host "  - Detailed Report: $detailedReportPath" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""

    # Disconnect
    Disconnect-PnPOnline
}

# Run main function
Main
