function Get-AutopilotPolicy {
[cmdletbinding()]
    
param
(
    [System.IO.FileInfo]$FileDestination
    ,
    [string]$tenant #Tenant ID (optional) for when automating and you want to use across tenants instead of hard-coded
    ,
    [string]$clientid #ClientID is the type of Azure AD App Reg ID
    ,
    [string]$clientsecret #ClientSecret is the type of Azure AD App Reg Secret

    )



###############################################################################################################
######                                         Install Modules                                           ######
###############################################################################################################
Write-Host "Installing Intune modules if required (current user scope)"

#Install MS Graph if not available
if (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication) {
    Write-Host "Microsoft Graph Already Installed"
} 
else {

        Install-Module -Name Microsoft.Graph.Authentication -Scope CurrentUser -Repository PSGallery -Force 

}

import-module microsoft.graph.authentication

###############################################################################################################
######                                          Create Dir                                               ######
###############################################################################################################

#Create path for files
$DirectoryToCreate = "c:\temp"
if (-not (Test-Path -LiteralPath $DirectoryToCreate)) {
    
    try {
        New-Item -Path $DirectoryToCreate -ItemType Directory -ErrorAction Stop | Out-Null #-Force
    }
    catch {
        Write-Error -Message "Unable to create directory '$DirectoryToCreate'. Error was: $_" -ErrorAction Stop
    }
    "Successfully created directory '$DirectoryToCreate'."

}
else {
    "Directory already existed"
}


$random = Get-Random -Maximum 1000 
$random = $random.ToString()
$date =get-date -format yyMMddmmss
$date = $date.ToString()
$path2 = $random + "-"  + $date
$path = "c:\temp\" + $path2

New-Item -ItemType Directory -Path $path

###############################################################################################################
######                                          Add Functions                                            ######
###############################################################################################################

function GrabProfiles() {

    # Defining Variables
$graphApiVersion = "beta"
$Resource = "deviceManagement/windowsAutopilotDeploymentProfiles"

$uri = "https://graph.microsoft.com/$graphApiVersion/$Resource"
$response = Invoke-MGGraphRequest -Uri $uri -Method Get -OutputType PSObject

    $profiles = $response.value

    $profilesNextLink = $response."@odata.nextLink"

    while ($null -ne $profilesNextLink) {
        $profilesResponse = (Invoke-MGGraphRequest -Uri $profilesNextLink -Method Get -outputType PSObject)
        $profilesNextLink = $profilesResponse."@odata.nextLink"
        $profiles += $profilesResponse.value
    }

    $selectedprofile = $profiles | out-gridview -passthru -title "Select a profile"
    return $selectedprofile.id

}

function grabandoutput() {
[cmdletbinding()]

param
(
[string]$id

)

        # Defining Variables
        $graphApiVersion = "beta"
    $Resource = "deviceManagement/windowsAutopilotDeploymentProfiles"

$uri = "https://graph.microsoft.com/$graphApiVersion/$Resource/$id"
$approfile = Invoke-MGGraphRequest -Uri $uri -Method Get -OutputType PSObject

# Set the org-related info
$script:TenantOrg = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/organization" -OutputType PSObject).value
foreach ($domain in $script:TenantOrg.VerifiedDomains) {
    if ($domain.isDefault) {
        $script:TenantDomain = $domain.name
    }
}
$oobeSettings = $approfile.outOfBoxExperienceSettings

# Build up properties
$json = @{}
$json.Add("Comment_File", "Profile $($_.displayName)")
$json.Add("Version", 2049)
$json.Add("ZtdCorrelationId", $_.id)
if ($approfile."@odata.type" -eq "#microsoft.graph.activeDirectoryWindowsAutopilotDeploymentProfile") {
    $json.Add("CloudAssignedDomainJoinMethod", 1)
}
else {
    $json.Add("CloudAssignedDomainJoinMethod", 0)
}
if ($approfile.deviceNameTemplate) {
    $json.Add("CloudAssignedDeviceName", $_.deviceNameTemplate)
}

# Figure out config value
$oobeConfig = 8 + 256
if ($oobeSettings.userType -eq 'standard') {
    $oobeConfig += 2
}
if ($oobeSettings.hidePrivacySettings -eq $true) {
    $oobeConfig += 4
}
if ($oobeSettings.hideEULA -eq $true) {
    $oobeConfig += 16
}
if ($oobeSettings.skipKeyboardSelectionPage -eq $true) {
    $oobeConfig += 1024
    if ($_.language) {
        $json.Add("CloudAssignedLanguage", $_.language)
    }
}
if ($oobeSettings.deviceUsageType -eq 'shared') {
    $oobeConfig += 32 + 64
}
$json.Add("CloudAssignedOobeConfig", $oobeConfig)

# Set the forced enrollment setting
if ($oobeSettings.hideEscapeLink -eq $true) {
    $json.Add("CloudAssignedForcedEnrollment", 1)
}
else {
    $json.Add("CloudAssignedForcedEnrollment", 0)
}

$json.Add("CloudAssignedTenantId", $script:TenantOrg.id)
$json.Add("CloudAssignedTenantDomain", $script:TenantDomain)
$embedded = @{}
$embedded.Add("CloudAssignedTenantDomain", $script:TenantDomain)
$embedded.Add("CloudAssignedTenantUpn", "")
if ($oobeSettings.hideEscapeLink -eq $true) {
    $embedded.Add("ForcedEnrollment", 1)
}
else {
    $embedded.Add("ForcedEnrollment", 0)
}
$ztc = @{}
$ztc.Add("ZeroTouchConfig", $embedded)
$json.Add("CloudAssignedAadServerData", (ConvertTo-JSON $ztc -Compress))

# Skip connectivity check
if ($approfile.hybridAzureADJoinSkipConnectivityCheck -eq $true) {
    $json.Add("HybridJoinSkipDCConnectivityCheck", 1)
}

# Hard-code properties not represented in Intune
$json.Add("CloudAssignedAutopilotUpdateDisabled", 1)
$json.Add("CloudAssignedAutopilotUpdateTimeout", 1800000)

# Return the JSON
ConvertTo-JSON $json
}

Function Connect-ToGraph {
    
    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory = $false)] [string]$Tenant,
        [Parameter(Mandatory = $false)] [string]$AppId,
        [Parameter(Mandatory = $false)] [string]$AppSecret,
        [Parameter(Mandatory = $false)] [string]$scopes
    )

    Process {
        Import-Module Microsoft.Graph.Authentication
        $version = (get-module microsoft.graph.authentication | Select-Object -expandproperty Version).major

        if ($AppId -ne "") {
            $body = @{
                grant_type    = "client_credentials";
                client_id     = $AppId;
                client_secret = $AppSecret;
                scope         = "https://graph.microsoft.com/.default";
            }
     
            $response = Invoke-RestMethod -Method Post -Uri https://login.microsoftonline.com/$Tenant/oauth2/v2.0/token -Body $body
            $accessToken = $response.access_token
     
            $accessToken
            if ($version -eq 2) {
                write-host "Version 2 module detected"
                $accesstokenfinal = ConvertTo-SecureString -String $accessToken -AsPlainText -Force
            }
            else {
                write-host "Version 1 Module Detected"
                Select-MgProfile -Name Beta
                $accesstokenfinal = $accessToken
            }
            $graph = Connect-MgGraph  -AccessToken $accesstokenfinal 
            Write-Host "Connected to Intune tenant $TenantId using app-based authentication (Azure AD authentication not supported)"
        }
        else {
            if ($version -eq 2) {
                write-host "Version 2 module detected"
            }
            else {
                write-host "Version 1 Module Detected"
                Select-MgProfile -Name Beta
            }
            $graph = Connect-MgGraph -scopes $scopes
            Write-Host "Connected to Intune tenant $($graph.TenantId)"
        }
    }
}    
###############################################################################################################
######                                        Graph Connection                                           ######
###############################################################################################################

Write-Verbose "Connecting to Microsoft Graph"

if ($clientid -and $clientsecret -and $tenant) {
Connect-ToGraph -Tenant $tenant -AppId $clientid -AppSecret $clientsecret
write-output "Graph Connection Established"
}
else {
##Connect to Graph
Connect-ToGraph -scopes "Group.ReadWrite.All, Device.ReadWrite.All, DeviceManagementManagedDevices.ReadWrite.All, DeviceManagementServiceConfig.ReadWrite.All, GroupMember.ReadWrite.All, Domain.ReadWrite.All, Organization.Read.All"
}
Write-Verbose "Graph connection established"
###############################################################################################################
######                                              Execution                                            ######
###############################################################################################################

##Grab all profiles and output to gridview
$selectedprofile = GrabProfiles

##Grab JSON for selected profile
$profilejson = grabandoutput -id $selectedprofile

##Inject the Autopilot JSON
write-host "Injecting Autopilot JSON"
$profilejson | Set-Content -Encoding Ascii "$FileDestination\AutopilotConfigurationFile.json"
write-host "JSON Injected"
}
