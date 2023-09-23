using module 'classes\ImageUSB.psm1'

#region Get public and private function definition files.
#$Public  = @(Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue)
$Public  = @(Get-ChildItem -Path $PSScriptRoot\Public\*.ps1)
#$Private = @(Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path $PSScriptRoot\Private\*.ps1)
$script:provisionUrl = "https://raw.githubusercontent.com/cruzerdlc/Windows-11-AP-USB-Creator/main/Invoke-Provision/Invoke-Provision.ps1"
#endregion
#region Dot source the files
foreach ($import in @($Public + $Private))
{
    try
    {
        . $import.FullName
    }
    catch
    {
        Write-Error -Message "Failed to import function $($import.FullName): $_"
    }
}
#endregion