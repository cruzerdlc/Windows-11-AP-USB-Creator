#
# Module manifest for module 'Intune.USB.Creator'
#
# Generated by: Ben Reader
#
# Generated on: 12/14/2021
#
# Modified by: Jorge.I.O.
#
# Modified on" 09/2023
# Converted to create windows 11 usb key.
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'Intune.USB.Creator.psm1'

# Version number of this module.
ModuleVersion = '1.0.1.315'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = '33d73c2d-74a1-47d4-b1e8-693974aa741c'

# Author of this module
Author = 'Ben Reader'

# Company or vendor of this module
CompanyName = 'Powers-Hell'

# Copyright statement for this module
Copyright = '(c) 2020 Ben Reader. All rights reserved.'

# Description of the functionality provided by this module
Description = 'A module containing tools to assist with the creation of a bootable WinPE USB used to provision devices for enrollment to Intune.'

# Minimum version of the PowerShell engine required by this module
# PowerShellVersion = ''

# Name of the PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# ClrVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @(@{ModuleName = 'WindowsAutoPilotIntune'; ModuleVersion = '4.3'; }, 
               @{ModuleName = 'Microsoft.Graph.Intune'; ModuleVersion = '6.1907.1.0'; })

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = 'Publish-ImageToUSB'

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @()

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = 'Intune','Azure','Automation'

        # A URL to the license for this module.
        # LicenseUri = ''

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/cruzerdlc/Windows-11-AP-USB-Creator/'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = '1.0.1.315
  - "diskNum" parameter will now correctly (and silently) pass the selected disk number with no user interaction required.

1.0.1.314
  - Updated Invoke-Provision to allow driver bootstrapping. Should allow all devices to work seamlessly with the tool. 🍻🍻🍻

1.0.1.313
  - Forcing version of PowerShell to 7.0.3 to fix reported problems with WinPE & PowerShell 7.1


1.0.1.312
  - Fixes issues with WinPE extraction. (Thanks to Peter C. for troubleshooting this one)
  - Fixes issues with multiple autopilot policies not downloading properly.


1.0.1.311
  - ImageIndex & DiskNum variables added to allow non-interactive use of module. (Thanks axgch)

1.0.1.309
- USB size check implemented - no smaller than 8gb. (Thanks Rob)
  - Autopilot provisioning path now tested (Thanks Rob)
  - Removed daily flag from pwsh7 installer ( Thanks jmaystahl)
  ----
  - Adding in warning messages to invoke-provision script.
  - Moved Invoke-Provision out of the WinPE media and now pulling from GitHub.
  - Updated module dependencies to be auto-installed
  - Removed support for Out-ConsoleGridView for less required dependencies
  - Improved windows PowerShell compatibility for modules not natively supported in PowerShell 7.'

        # Prerelease string of this module
        # Prerelease = ''

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        # RequireLicenseAcceptance = $false

        # External dependent modules of this module
        # ExternalModuleDependencies = @()

    } # End of PSData hashtable

 } # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

