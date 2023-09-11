#requires -Modules @{ ModuleName="WindowsAutoPilotIntune"; ModuleVersion="4.3" }
#requires -Modules @{ ModuleName="Microsoft.Graph.Intune"; ModuleVersion="6.1907.1.0"}
Connect-MgGraph -Scopes "Device.ReadWrite.All", "DeviceManagementManagedDevices.ReadWrite.All", "DeviceManagementServiceConfig.ReadWrite.All", "Domain.ReadWrite.All", "Group.ReadWrite.All", "GroupMember.ReadWrite.All", "User.Read"
           
function Get-AutopilotPolicy {
    [cmdletbinding()]
    param (
        [parameter(Mandatory = $true)]
        [System.IO.FileInfo]$FileDestination
    )
    try {
        if (!(Test-Path "$FileDestination\AutopilotConfigurationFile.json" -ErrorAction SilentlyContinue)) {
            $modules = @(
                "WindowsAutoPilotIntune",
                "Microsoft.Graph.Intune",
				"AzureAD"
            )
            if ($PSVersionTable.PSVersion.Major -eq 7) {
                $modules | ForEach-Object {
                    Import-Module $_ -UseWindowsPowerShell -ErrorAction SilentlyContinue 3>$null
                }
            }
            else {
                $modules | ForEach-Object {
                    Import-Module $_
                }
            }
            #region Connect to Intune
			Connect-MgGraph -Scopes "Device.ReadWrite.All", "DeviceManagementManagedDevices.ReadWrite.All", "DeviceManagementServiceConfig.ReadWrite.All", "Domain.ReadWrite.All", "Group.ReadWrite.All", "GroupMember.ReadWrite.All", "User.Read"
           

            
            $apPolicies = Get-AutopilotProfile
            if (!($apPolicies)) {
                Write-Warning "No Autopilot policies found.."
            }
            else {
                if ($apPolicies.count -gt 1) {
                    Write-Host "Multiple Autopilot policies found - select the correct one.." -ForegroundColor Cyan
                    $selectedPolicy = $apPolicies | Select-Object displayName | 
                    Out-GridView -PassThru |
                    ForEach-Object{Get-Content $_.displayName | Set-Clipboard -Append}
                    $apPol = $apPolicies | Where-Object {$_.displayName -eq $selectedPolicy.displayName}
                }
                else {
                    Write-Host "Policy found - saving to $FileDestination.." -ForegroundColor Cyan
                    $apPol = $apPolicies
                }
                $apPol | ConvertTo-AutopilotConfigurationJSON | Out-File "$FileDestination\AutopilotConfigurationFile.json" -Encoding ascii -Force
                Write-Host "Autopilot profile selected: " -ForegroundColor Cyan -NoNewline
                Write-Host "$($apPol.displayName)" -ForegroundColor Green
            }
            #endregion Get policies
        }
        else {
            Write-Host "Autopilot Configuration file found locally: $FileDestination\AutopilotConfigurationFile.json" -ForegroundColor Green
        }
    }
    catch {
        $errorMsg = $_
    }
    finally {
        if ($PSVersionTable.PSVersion.Major -eq 7) {
            $modules = @(
                "WindowsAutoPilotIntune",
                "Microsoft.Graph.Intune"
            ) | ForEach-Object {
                Remove-Module $_ -ErrorAction SilentlyContinue 3>$null
            }
        }
        if ($errorMsg) {
            Write-Warning $errorMsg
        }
    }
}