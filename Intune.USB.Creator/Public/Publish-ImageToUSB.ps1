function Publish-ImageToUSB {
    [cmdletbinding()]
    param (
        [parameter(ParameterSetName = "Build", Mandatory = $true)]
        [parameter(ParameterSetName = "Default", Mandatory = $true)]
        [string]$winPEPath,

        [parameter(ParameterSetName = "Build", Mandatory = $true)]
        [parameter(ParameterSetName = "Default", Mandatory = $true)]
        [string]$windowsIsoPath,

        [parameter(ParameterSetName = "Build", Mandatory = $false)]
        [parameter(ParameterSetName = "Default", Mandatory = $false)]
        [switch]$getAutoPilotCfg,

        [parameter(ParameterSetName = "Build", Mandatory = $true)]
        [string]$imageIndex,

        [parameter(ParameterSetName = "Build", Mandatory = $true)]
        [string]$diskNum
    )
    #region Main Process
    try {
        #region start diagnostic // show welcome
        $errorMsg = $null
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $welcomeScreen = "CuKWhOKWhOKWhOKWhOKWhOKWhOKWhOKWhOKWhOKWhOKWhOKWhOKWhOKWhOKWhOKWhOKWhOKWhOKWhOKWhOKWhOKWhOKWhOKWhOKWhOKWhOKWhOKWhOKWhOKWhOKWhOKWhOKWhOKWhOKWhOKWhOKWhOKWhOKWhOKWhOKWhOKWhOKWhOKWhOKWhArilojilojilojilojilojilpHilojiloDiloTiloTiloDilojilpHiloTiloTiloDilojilpHiloTiloTiloTilojilpHiloTiloTilojilojilojilojiloTilpHiloTilojilojilojilojilojilpHiloTiloTiloTilpHilojilojilogK4paI4paI4paI4paI4paI4paR4paI4paR4paI4paI4paR4paI4paR4paA4paA4paE4paI4paR4paI4paE4paA4paI4paR4paE4paE4paI4paA4paA4paI4paI4paR4paI4paI4paA4paA4paI4paI4paR4paI4paI4paI4paR4paI4paA4paACuKWiOKWiOKWkeKWgOKWgOKWkeKWiOKWiOKWhOKWhOKWiOKWiOKWhOKWiOKWhOKWhOKWiOKWhOKWhOKWhOKWhOKWiOKWhOKWhOKWhOKWiOKWhOKWhOKWiOKWgOKWkeKWgOKWiOKWhOKWhOKWiOKWiOKWkeKWgOKWgOKWgOKWkeKWiOKWhOKWhAriloDiloDiloDiloDiloDiloDiloDiloDiloDiloDiloDiloDiloDiloDiloDiloDiloDiloDiloDiloDiloDiloDiloDiloDiloDiloDiloDiloDiloDiloDiloDiloDiloDiloDiloDiloDiloDiloDiloDiloDiloDiloDiloDiloDiloAKCioqKioqKioqKioqKioqKioqKldpbmRvd3MgMTEgUHJvdmlzaW9uaW5nIFRvb2wqKioqKioqKioqKioqKioqKioqKioqKioqKioqKio="
        Write-Host $([system.text.encoding]::UTF8.GetString([system.convert]::FromBase64String($welcomeScreen)))
        if (!(Test-Admin)) {
            throw "Exiting -- need admin right to execute"
        }
        #endregion
        #region set usb class
        Write-Host "`nSetting up configuration paths.." -ForegroundColor Yellow
        $usb = [ImageUSBClass]::new()
        #endregion
        #region get winPE / unpack to temp
        Write-Host "`nGetting WinPE media.." -ForegroundColor Yellow
        Get-RemoteFile -fileUri $winPEPath -destination $usb.downloadPath -expand
        #endregion
        #region get wim from ISO
        Write-Host "`nGetting install.wim from windows media.." -ForegroundColor Yellow -NoNewline
        if (Test-Path -Path $windowsIsoPath -ErrorAction SilentlyContinue) {
            $dlFile = $windowsIsoPath
        }
        else {
            $dlFile = Get-RemoteFile -fileUri $windowsIsoPath -destination $usb.downloadPath
        }
        Get-WimFromIso -isoPath $dlFile -wimDestination $usb.WIMPath
        #endregion
        #region get image index from wim
        if ($imageIndex) {
            @{
                "ImageIndex" = $imageIndex
            } | ConvertTo-Json | Out-File "$($usb.downloadPath)\$($usb.dirName2)\imageIndex.json"
        }
        else {
            Write-Host "`nGetting image index from install.wim.." -ForegroundColor Yellow
            Get-ImageIndexFromWim -wimPath $usb.WIMFilePath -destination "$($usb.downloadPath)\$($usb.dirName2)"
        }
        #endregion
        #region get Autopilot config from azure
        if ($getAutopilotCfg) {
            Write-Host "`nGrabbing Autopilot config file from Azure.." -ForegroundColor Yellow
            Get-AutopilotPolicy -fileDestination $usb.downloadPath
        }
        #endregion
        #region choose and partition USB
        Write-Host "`nConfiguring USB.." -ForegroundColor Yellow
        if ($PsCmdlet.ParameterSetName -eq "Build") {
            $chooseDisk = Get-DiskToUse -diskNum $diskNum
        }
        else {
            $chooseDisk = Get-DiskToUse
        }
        Write-Host "`nDisk number " $diskNum " selected." -ForegroundColor Cyan
        $usb = Set-USBPartition -usbClass $usb -diskNum $chooseDisk
        #endregion
        #region write WinPE to USB
        Write-Host "`nWriting WinPE to USB.." -ForegroundColor Yellow -NoNewline
        Write-ToUSB -Path "$($usb.winPEPath)\*" -Destination "$($usb.drive):\"
        #endregion
        #region write Install.wim to USB
        if ($windowsIsoPath) {
            Write-Host "`nWriting Install.wim to USB.." -ForegroundColor Yellow -NoNewline
            Write-ToUSB -Path $usb.WIMPath -Destination "$($usb.drive2):\"
        }
        #endregion
        #region write Autopilot to USB
        if ($getAutopilotCfg) {
            Write-Host "`nWriting Autopilot to USB.." -ForegroundColor Yellow -NoNewline
            Write-ToUSB -Path "$($usb.downloadPath)\AutopilotConfigurationFile.json" -Destination "$($usb.drive):\scripts\"
        }
        #endregion
        #region Create drivers folder
        Write-Host "`nSetting up folder structures for Drivers.." -ForegroundColor Yellow -NoNewline
        New-Item -Path "$($usb.drive2):\Drivers" -ItemType Directory -Force | Out-Null
        #endregion
        #region download provision script and install to usb
        Write-Host "`nGrabbing provision script from GitHub.." -ForegroundColor Yellow
        Invoke-RestMethod -Method Get -Uri $script:provisionUrl -OutFile "$($usb.drive):\scripts\Invoke-Provision.ps1"
        #endregion
        #region download and apply powershell 7 to usb
        Write-Host "`nGrabbing PWSH 7.0.3.." -ForegroundColor Yellow
        Invoke-RestMethod -Method Get -Uri 'https://github.com/PowerShell/PowerShell/releases/download/v7.0.3/PowerShell-7.0.3-win-x64.zip' -OutFile "$env:Temp\pwsh7.zip"
        Expand-Archive -path "$env:Temp\pwsh7.zip" -Destinationpath "$($usb.drive):\scripts\pwsh"
        #endregion download and apply powershell 7 to usb
        $completed = $true
    }
    catch {
        $errorMsg = $_.Exception.Message
    }
    finally {
        $sw.Stop()
        if ($errorMsg) {
            Write-Warning $errorMsg
        }
        else {
            if ($completed) {
                Write-Host "`nUSB Image built successfully..`nTime taken: $($sw.Elapsed)" -ForegroundColor Green
            }
            else {
                Write-Host "`nScript stopped before completion..`nTime taken: $($sw.Elapsed)" -ForegroundColor Green
            }
        }
    }
    #endregion
}
