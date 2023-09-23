# Windows-11-AP-USB-Creator  <until I Publish this>
How to install
Create a folder called windows11.usbcreator in C:\Program Files\WindowsPowerShell\Modules
 i/e C:\Program Files\WindowsPowerShell\Modules\windows11.usbcreator
Unzip the module into this folder.
should now have 3 folders Classes Private and Public
And 2 files in the root Windows11.usbcreator.psd1
and Windows11.usbcreator.psm1

Open Powershell as an Admin and run the below from inside the folder windows11.usbcreator
Import-module -name windows11.usbcreator -Verbose -Force
You should see the below.
VERBOSE: Loading module from path 'C:\Program Files\WindowsPowerShell\Modules\windows11.usbcreator\windows11.usbcreator.psd1'.
VERBOSE: Loading module from path 'C:\Program Files\WindowsPowerShell\Modules\windows11.usbcreator\windows11.usbcreator.psm1'.
VERBOSE: Exporting function 'win11usbcreator'.
VERBOSE: Exporting function 'Expand-Download'.
VERBOSE: Exporting function 'Get-AutopilotPolicy'.
VERBOSE: Exporting function 'Get-DiskToUse'.                                                                                                                                           
VERBOSE: Exporting function 'Get-ImageIndexFromWim'.                                                                                                                                   
VERBOSE: Exporting function 'Get-RemoteFile'.                                                                                                                                          
VERBOSE: Exporting function 'Get-WimFromIso'.                                                                                                                                          
VERBOSE: Exporting function 'Invoke-FileTransfer'.                                                                                                                                     
VERBOSE: Exporting function 'Set-USBPartition'.                                                                                                                                        
VERBOSE: Exporting function 'Test-Admin'.                                                                                                                                              
VERBOSE: Exporting function 'Test-DiskSpace'.
VERBOSE: Exporting function 'Write-ToUSB'.
VERBOSE: Importing function 'win11usbcreator'.



How to run
Coomand = win11usbcreator
Options
-getAutoPilotCFG This will poll intune and proide a list of all Autopilot config file to select from. Select one then ok.
-AutoPilotPath  This will grab the .zip file with all the offline autopilot files.
	For more info on this see "https://learn.microsoft.com/en-us/mem/intune/enrollment/windows-bulk-enroll"
	Run this on a computer that is NOT enrolled in any MDM's
Mandatory
-winPEPath This is the path of your windows pe file in ZIP format
-WindowsISOPath This is the path of your windows image in .ISO format. can be win11 or win10

win11usbcreator -winPEPath (path to winpe zip file) -windowsISOPath (path to windows 11 iso) -autopilotpath (path to .zip with offline prov profile OPTIONAL) -getAutoPilotCFG (downloads autopilot config and converts to json to inject into image OPTIONAL)

Example
win11usbcreator -winPEPath "C:\Downloads\WinPE.zip" -windowsIsoPath "C:\Downloads\win11litecert.iso" -autopilotpath "C:\Downloads\provisiong profile\provisioning.zip" -getAutoPilotCfg

