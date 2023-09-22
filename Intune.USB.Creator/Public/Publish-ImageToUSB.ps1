function Publish-ImageToUSB {
    [cmdletbinding()]
    param (
        [parameter(ParameterSetName = "Build", Mandatory = $true)]
        [parameter(ParameterSetName = "Default", Mandatory = $true)]
        [string]$winPEPath,

        [parameter(ParameterSetName = "Build", Mandatory = $true)]
        [parameter(ParameterSetName = "Default", Mandatory = $true)]
        [string]$windowsIsoPath,

        [parameter(ParameterSetName = "Build", Mandatory = $true)]
        [parameter(ParameterSetName = "Default", Mandatory = $true)]
        [string]$AutoPilotPath,

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
        $welcomeScreen = "ICAgIF9fICBfXyAgICBfXyAgX19fX19fICBfX19fX18gIF9fX19fXw0KICAgL1wgXC9cICItLi8gIFwvXCAgX18gXC9cICBfX19cL1wgIF9fX1wNCiAgIFwgXCBcIFwgXC0uL1wgXCBcICBfXyBcIFwgXF9fIFwgXCAgX19cDQogICAgXCBcX1wgXF9cIFwgXF9cIFxfXCBcX1wgXF9fX19fXCBcX19fX19cDQogICAgIFwvXy9cL18vICBcL18vXC9fL1wvXy9cL19fX19fL1wvX19fX18vDQogX19fX19fICBfXyAgX18gIF9fICBfXyAgICAgIF9fX19fICAgX19fX19fICBfX19fX18NCi9cICA9PSBcL1wgXC9cIFwvXCBcL1wgXCAgICAvXCAgX18tLi9cICBfX19cL1wgID09IFwNClwgXCAgX188XCBcIFxfXCBcIFwgXCBcIFxfX19cIFwgXC9cIFwgXCAgX19cXCBcICBfXzwNCiBcIFxfX19fX1wgXF9fX19fXCBcX1wgXF9fX19fXCBcX19fXy1cIFxfX19fX1wgXF9cIFxfXA0KICBcL19fX19fL1wvX19fX18vXC9fL1wvX19fX18vXC9fX19fLyBcL19fX19fL1wvXy8gL18vDQogICAgICAgICBfX19fX19fX19fX19fX19fX19fX19fX19fX19fX19fX19fXw0KICAgICAgICAgV2luZG93cyAxMSBEZXZpY2UgUHJvdmlzaW9uaW5nIFRvb2wNCiAgICAgICAgICoqKioqKioqKioqKioqKioqKioqKioqKioqKioqKioqKioq"
        Write-Host $([system.text.encoding]::UTF8.GetString([system.convert]::FromBase64String($welcomeScreen)))
        if (!(Test-Admin)) {
            throw "Exiting -- need admin right to execute"
        }
        #endregion
        #region set usb class
        Write-Host "`nSetting up configuration paths..p" -ForegroundColor Yellow
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
        if ($AutoPilotCfgPath) {
            Write-Host "`nWriting Autopilot config to USB.." -ForegroundColor Yellow -NoNewline
            Write-ToUSB -Path "$($usb.$AutoPilotCfgPath)" -Destination "$($usb.drive):\" -expand
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
