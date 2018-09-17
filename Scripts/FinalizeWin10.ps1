<#
.SYNOPSIS
Finalize Windows 10 Script

.DESCRIPTION
Changes settings of a Windows 10 install at the end of an MDT Deployment.

Version: 4.2 
Last Updated: 09/17/2018 
Created: 07/20/2018 
Author: John Suit 
Entity: Penn State Facilities Engineering Institute 

.NOTES
This script was intended for use with Windows 10 Professional 64-bit, version 1803. 
Tested on Windows 10 Educational source media with all Windows 10 versions available 
To use this script:
1.) Edit it as desired (should work as-is for most deployments)
2.) Save it to your MDT Deploy\Scripts folder
3.) Include it in an MDT Task Sequence
Optional: Include radiostatus.ps1 andDisableWiFi.xml in Deploy\Scritps folder to utilize turning off wifi


Copyright The Pennsylvania State University © 2018
License: GNU GPL 3.0

References:	Group Policy ADMX files, or online at https://getadmx.com/
			http://servicedefaults.com/10/
			http://www.blackviper.com/service-configurations/black-vipers-windows-10-service-configurations/
			https://michlstechblog.info/blog/windows-10-powershell-script-to-protect-your-privacy/
			https://docs.microsoft.com/en-us/windows/application-management/apps-in-windows-10
			https://www.vacuumbreather.com/index.php/blog/item/69-windows-10-1803-built-in-apps-what-to-keep
			https://arstechnica.com/information-technology/2015/08/even-when-told-not-to-windows-10-just-cant-stop-talking-to-microsoft/
			https://ss64.com/nt/syntax-reghacks.html
			https://jrich523.wordpress.com/2012/03/06/powershell-loading-and-unloading-registry-hives/
			https://stackoverflow.com/questions/255419/how-can-i-mute-unmute-my-sound-from-powershell/19348221#19348221
#>

# ----------[ Miscellaneous Variables ]------------------------------------------------------------------------------------------------
[string]$overallAct = "Finalize Windows 10 Script, version 4.2"
[string]$currentAct = "Configuring"
Write-Verbose "$currentAct ..."
Write-Progress -Activity $overallAct -Status $currentAct -Id 1
$ErrorActionPreference = "SilentlyContinue"
if ([string]::IsNullOrEmpty($DEPLOYROOT))
{
	$DEPLOYROOT = (Get-Location).Drive.Name + ":\Deploy"
}
[string]$featurePath = "$DEPLOYROOT\Scripts\Features"

# ----------[ Registry Path Variables ]------------------------------------------------------------------------------------------------
[string]$CUControl = "Registry::HKEY_CURRENT_USER\Control Panel"
[string]$CUExpAdv = "Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
[string]$CUSoftMS = "Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft"
[string]$CUWinCurrent = "Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion"
[string]$CUWinCurCDM = "Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
[string]$CUWinCurDev = "Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global"
[string]$LMWinCurrent = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion"
[string]$LMPolicyMS = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft"
[string]$LMPolicyMS64 = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft"
[string]$LMControlServices = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services"
[string]$LMControlSet = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control"
[string]$UControl = "Registry::HKEY_USERS\DefaultUser\Control Panel"
[string]$USoftMS = "Registry::HKEY_USERS\DefaultUser\SOFTWARE\Microsoft"
[string]$UWinCurCDM = "Registry::HKEY_USERS\DefaultUser\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
[string]$UWinCurDev = "Registry::HKEY_USERS\DefaultUser\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global"
[string]$UWinCurrent = "Registry::HKEY_USERS\DefaultUser\SOFTWARE\Microsoft\Windows\CurrentVersion"
[string]$UExpAdv = "Registry::HKEY_USERS\DefaultUser\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

# ----------[ Load Default User into Registry ]----------------------------------------------------------------------------------------
[string]$currentAct = "Loading default user hive"
Write-Verbose "$currentAct ..."
Write-Progress -Activity $overallAct -Status $currentAct -Id 2
reg.exe LOAD "HKU\DefaultUser" "$env:SYSTEMDRIVE\Users\Default\NTUSER.DAT" | out-null

# ----------[ Install WiFiDisable Scheduled Task ]-------------------------------------------------------------------------------------
[string]$currentAct = "Installing scheduled tasks"
Write-Verbose "$currentAct ..."
Write-Progress -Activity $overallAct -Status $currentAct -Id 3
Set-Service -Name "dot3svc" -StartupType Automatic | out-null
Start-Service -Name "dot3svc" | out-null
if (Test-Path "$DEPLOYROOT\Scripts\radiostatus.ps1")
{
	Copy-Item "$DEPLOYROOT\Scripts\radiostatus.ps1" -Destination "$env:SYSTEMROOT\radiostatus.ps1" -Force | out-null
	if (Test-Path "$DEPLOYROOT\Scripts\DisableWiFi.xml")
	{
		Register-ScheduledTask -TaskName "DisableWiFi" -Xml (Get-Content "$DEPLOYROOT\Scripts\DisableWiFi.xml" | Out-String) -Force | out-null
	}
}

# ----------[ Remote Desktop ]---------------------------------------------------------------------------------------------------------
[string]$currentAct = "Activating remote dekstop and modifying security settings"
Write-Verbose "$currentAct ..."
Write-Progress -Activity $overallAct -Status $currentAct -Id 4
New-ItemProperty -Path "$LMControlSet\Terminal Server" -Name fDenyTSConnections -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$LMControlSet\Terminal Server\WinStations\RDP-Tcp" -Name UserAuthentication -PropertyType DWord -Value 1 -Force | out-null
Enable-NetFirewallRule -DisplayGroup "Remote Desktop" | out-null

# ----------[ Content Delivery ]-------------------------------------------------------------------------------------------------------
[string]$currentAct = "Disabling suggested and pre-installed apps"
Write-Verbose "$currentAct ..."
Write-Progress -Activity $overallAct -Status $currentAct -Id 5
New-ItemProperty -Path "$CUWinCurCDM" -Name ContentDeliveryAllowed -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$CUWinCurCDM" -Name OemPreInstalledAppsEnabled -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$CUWinCurCDM" -Name PreInstalledAppsEnabled -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$CUWinCurCDM" -Name PreInstalledAppsEverEnabled -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$CUWinCurCDM" -Name RotatingLockScreenEnabled -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$CUWinCurCDM" -Name RotatingLockScreenOverlayEnabled -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$CUWinCurCDM" -Name SilentInstalledAppsEnabled -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$CUWinCurCDM" -Name SoftLandingEnabled -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$CUWinCurCDM" -Name SubscribedContent-338388Enabled -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$CUWinCurCDM" -Name SubscribedContent-338389Enabled -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$CUWinCurCDM" -Name SystemPaneSuggestionsEnabled -PropertyType DWord -Value 0 -Force | out-null
# Content Devlivery settings for default user (each subsequent user that logs in)...
New-Item -Path "$UWinCurrent" -Name ContentDeliveryManager -Force | out-null
New-ItemProperty -Path "$UWinCurCDM" -Name ContentDeliveryAllowed -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$UWinCurCDM" -Name OemPreInstalledAppsEnabled -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$UWinCurCDM" -Name PreInstalledAppsEnabled -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$UWinCurCDM" -Name PreInstalledAppsEverEnabled -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$UWinCurCDM" -Name RotatingLockScreenEnabled -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$UWinCurCDM" -Name RotatingLockScreenOverlayEnabled -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$UWinCurCDM" -Name SilentInstalledAppsEnabled -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$UWinCurCDM" -Name SoftLandingEnabled -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$UWinCurCDM" -Name SubscribedContent-338388Enabled -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$UWinCurCDM" -Name SubscribedContent-338389Enabled -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$UWinCurCDM" -Name SystemPaneSuggestionsEnabled -PropertyType DWord -Value 0 -Force | out-null

# ----------[ Telemetry ]--------------------------------------------------------------------------------------------------------------
[string]$currentAct = "Disabling telemetry"
Write-Verbose "$currentAct ..."
Write-Progress -Activity $overallAct -Status $currentAct -Id 6
# Microsoft Windows Malicious Software Removal Tool...
New-Item -Path "$LMPolicyMS" -Name MRT -Force | out-null
New-ItemProperty -Path "$LMPolicyMS\MRT" -Name DontOfferThroughWUAU -PropertyType DWord -Value 1 -Force | out-null
New-ItemProperty -Path "$LMPolicyMS\MRT" -Name DontReportInfectionInformation -PropertyType DWord -Value 1 -Force | out-null
# Windows Customer Experience Improvement Program...
New-Item -Path "$LMPolicyMS\SQMClient" -Name Windows -Force | out-null
New-ItemProperty -Path "$LMPolicyMS\SQMClient\Windows" -Name CEIPEnable -PropertyType DWord -Value 0 -Force | out-null
# Application/Program Compatibility...
New-Item -Path "$LMPolicyMS\Windows" -Name AppCompat -Force | out-null
New-ItemProperty -Path "$LMPolicyMS\Windows\AppCompat" -Name AITEnable -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$LMPolicyMS\Windows\AppCompat" -Name DisableInventory -PropertyType DWord -Value 1 -Force | out-null
New-ItemProperty -Path "$LMPolicyMS\Windows\AppCompat" -Name DisableUAR -PropertyType DWord -Value 1 -Force | out-null
# Windows Diagnostic Data...
New-ItemProperty -Path "$LMPolicyMS\Windows\DataCollection" -Name AllowTelemetry -PropertyType DWord -Value 0 -Force | out-null
# Device Metadata From Internet (we might want this enabled to show correct device icons)...
#New-ItemProperty -Path "$LMWinCurrent\Device Metadata" -Name PreventDeviceMetadataFromNetwork -PropertyType DWord -Value 1 -Force

# ----------[ Privacy Options ]--------------------------------------------------------------------------------------------------------
[string]$currentAct = "Setting privacy options"
Write-Verbose "$currentAct ..."
Write-Progress -Activity $overallAct -Status $currentAct -Id 7
# Website Access of Language List in Windows...
New-ItemProperty -Path "$CUControl\International\User Profile" -Name HttpAcceptLanguageOptOut -PropertyType DWord -Value 1 -Force | out-null
# Improve Inking & Typing Recognition (records typing, makes suggestions)...
New-ItemProperty -Path "$CUSoftMS\Input\TIPC" -Name Enabled -PropertyType DWord -Value 0 -Force | out-null
New-Item -Path "$CUSoftMS" -Name InputPersonalization -Force | out-null
New-ItemProperty -Path "$CUSoftMS\InputPersonalization" -Name RestrictImplicitTextCollection -PropertyType DWord -Value 1 -Force | out-null
New-ItemProperty -Path "$CUSoftMS\InputPersonalization" -Name RestrictImplicitInkCollection -PropertyType DWord -Value 1 -Force | out-null
New-Item -Path "$CUSoftMS\InputPersonalization" -Name TrainedDataStore -Force | out-null
New-ItemProperty -Path "$CUSoftMS\InputPersonalization\TrainedDataStore" -Name HarvestContacts -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$CUSoftMS\Personalization\Settings" -Name AcceptedPrivacyPolicy -PropertyType DWord -Value 0 -Force | out-null
# Windows to ask for Feedback and Diagnostics...
New-Item -Path "$CUSoftMS" -Name Siuf -Force | out-null
New-Item -Path "$CUSoftMS\Siuf" -Name Rules -Force | out-null
New-ItemProperty -Path "$CUSoftMS\Siuf\Rules" -Name NumberOfSIUFInPeriod -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$CUSoftMS\Siuf\Rules" -Name PeriodInNanoSeconds -PropertyType DWord -Value 0 -Force | out-null
# Windows Store Tracking...
New-Item -Path "$CUWinCurrent" -Name AdvertisingInfo -Force | out-null
New-ItemProperty -Path "$CUWinCurrent\AdvertisingInfo" -Name Enabled -PropertyType DWord -Value 0 -Force | out-null
# SmartScreen Filter (reports which websites you visit to Microsoft - let your antivirus/antimalware do this instead)...
New-ItemProperty -Path "$CUWinCurrent\AppHost" -Name EnableWebContentEvaluation -PropertyType DWord -Value 0 -Force | out-null
# Privacy Options from above for default user (each subsequent user that logs in)...
New-ItemProperty -Path "$UControl\International\User Profile" -Name HttpAcceptLanguageOptOut -PropertyType DWord -Value 1 -Force | out-null
New-ItemProperty -Path "$USoftMS\Input\TIPC" -Name Enabled -PropertyType DWord -Value 0 -Force | out-null
New-Item -Path "$USoftMS" -Name InputPersonalization -Force | out-null
New-ItemProperty -Path "$USoftMS\InputPersonalization" -Name RestrictImplicitTextCollection -PropertyType DWord -Value 1 -Force | out-null
New-ItemProperty -Path "$USoftMS\InputPersonalization" -Name RestrictImplicitInkCollection -PropertyType DWord -Value 1 -Force | out-null
New-Item -Path "$USoftMS\InputPersonalization" -Name TrainedDataStore -Force | out-null
New-ItemProperty -Path "$USoftMS\InputPersonalization\TrainedDataStore" -Name HarvestContacts -PropertyType DWord -Value 0 -Force | out-null
New-Item -Path "$USoftMS" -Name Personalization -Force | out-null
New-Item -Path "$USoftMS\Personalization" -Name Settings -Force | out-null
New-ItemProperty -Path "$USoftMS\Personalization\Settings" -Name AcceptedPrivacyPolicy -PropertyType DWord -Value 0 -Force | out-null
New-Item -Path "$USoftMS" -Name Siuf -Force | out-null
New-Item -Path "$USoftMS\Siuf" -Name Rules -Force | out-null
New-ItemProperty -Path "$USoftMS\Siuf\Rules" -Name NumberOfSIUFInPeriod -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$USoftMS\Siuf\Rules" -Name PeriodInNanoSeconds -PropertyType DWord -Value 0 -Force | out-null
New-Item -Path "$UWinCurrent" -Name AdvertisingInfo -Force | out-null
New-ItemProperty -Path "$UWinCurrent\AdvertisingInfo" -Name Enabled -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$UWinCurrent\AppHost" -Name EnableWebContentEvaluation -PropertyType DWord -Value 0 -Force | out-null
# Global Application Access for both current and default user...
New-Item -Path "$UWinCurrent" -Name DeviceAccess -Force | out-null
New-Item -Path "$UWinCurrent\DeviceAccess" -Name Global -Force | out-null
$accessGUIDs=@(
	"{21157C1F-2651-4CC1-90CA-1F28B02263F6}" # notifications: SMS, etc.
	"{235B668D-B2AC-4864-B49C-ED1084F6C9D3}" # phone call
	"{2EEF81BE-33FA-4800-9670-1CD474972C3F}" # microphone
	"{52079E78-A92B-413F-B213-E8FE35712E72}" # user notifications
	"{7D7E8402-7C54-4821-A34E-AEEFD62DED93}" # contacts
	"{8BC668CF-7728-45BD-93F8-CF2B3B41D7AB}" # phone history
	"{9231CB4C-BF57-4AF3-8C55-FDA7BFCC04C5}" # email
	"{992AFA70-6F47-4148-B3E9-3003349C1548}" # messages, chat, SMS ID, SMS send
	"{9D9E0118-1807-4F2E-96E4-2CE57142E196}" # activity sensors
	"{A8804298-2D5F-42E3-9531-9C8C39EB29CE}" # radios: wifi, bluetooth, etc.
	"{B19F89AF-E3EB-444B-8DEA-202575A71599}" # activity sensors: pedometer, etc.
	"{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" # location
	"{C1D23ACC-752B-43E5-8448-8D0E519CD6D6}" # user account: name, picture, etc.
	"{D89823BA-7180-4B81-B50C-7E471E6121A3}" # calendar: appointments, SMS companion, etc.
	"{E5323777-F976-4f5b-9B55-B94699C46E44}" # camera: webcam, etc.
	"{E6AD100E-5F4E-44CD-BE0F-2265D88D14F5}" # location history
	"LooselyCoupled" # sync with devices
)
foreach ($accessGUID in $accessGUIDs)
{
	if (!(Test-Path "$CUWinCurDev\$accessGUID")) { New-Item -Path "$CUWinCurDev" -Name "$accessGUID" -Force | out-null }
	New-ItemProperty -Path "$CUWinCurDev\$accessGUID" -Name Value -PropertyType String -Value DENY -Force | out-null
	New-Item -Path "$UWinCurDev" -Name "$accessGUID" -Force | out-null
	New-ItemProperty -Path "$UWinCurDev\$accessGUID" -Name Value -PropertyType String -Value DENY -Force | out-null
}

# ----------[ Windows Search & Cortana ]-----------------------------------------------------------------------------------------------
[string]$currentAct = "Changing search options"
Write-Verbose "$currentAct ..."
Write-Progress -Activity $overallAct -Status $currentAct -Id 8
# Change search on taskbar (0 = disabled, 1 = icon, 2 = full box)...
New-ItemProperty -Path "$CUWinCurrent\Search" -Name SearchboxTaskbarMode -PropertyType DWord -Value 1 -Force | out-null
# Bing Search...
New-ItemProperty -Path "$CUWinCurrent\Search" -Name BingSearchEnabled -PropertyType DWord -Value 0 -Force | out-null
# Cortana...
# (should be added to Unattend.xml instead)
#New-ItemProperty -Path "$LMPolicyMS\Windows\Windows Search" -Name AllowCortana -PropertyType DWord -Value 0 -Force
#New-ItemProperty -Path "$CUWinCurrent\Search" -Name CortanaConsent -PropertyType DWord -Value 0 -Force
# Search & Cortana for default user (each subsequent user that logs in)...
New-ItemProperty -Path "$UWinCurrent\Search" -Name SearchboxTaskbarMode -PropertyType DWord -Value 1 -Force | out-null
New-ItemProperty -Path "$UWinCurrent\Search" -Name BingSearchEnabled -PropertyType DWord -Value 0 -Force | out-null
#New-ItemProperty -Path "$UWinCurrent\Search" -Name CortanaConsent -PropertyType DWord -Value 0 -Force

# ----------[ Update Delivery Optimization ]-------------------------------------------------------------------------------------------
[string]$currentAct = "Disabling delivery optimization"
Write-Verbose "$currentAct ..."
Write-Progress -Activity $overallAct -Status $currentAct -Id 9
New-Item -Path "$LMPolicyMS\Windows" -Name DeliveryOptimization -Force | out-null
New-ItemProperty -Path "$LMPolicyMS\Windows\DeliveryOptimization" -Name DODownloadMode -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$LMWinCurrent\DeliveryOptimization\Config" -Name DODownloadMode -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$LMWinCurrent\DeliveryOptimization\Config" -Name DownloadMode -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$LMWinCurrent\DeliveryOptimization\Config" -Name DownloadMode_BackCompat -PropertyType DWord -Value 0 -Force | out-null

# ----------[ Networking ]-------------------------------------------------------------------------------------------------------------
[string]$currentAct = "Network configuration changes"
Write-Verbose "$currentAct ..."
Write-Progress -Activity $overallAct -Status $currentAct -Id 10
New-ItemProperty -Path "$LMPolicyMS\Windows\WcmSvc\GroupPolicy" -Name fBlockNonDomain -PropertyType DWord -Value 1 -Force | out-null

# ----------[ UAC Prompt ]-------------------------------------------------------------------------------------------------------------
[string]$currentAct = "Adjusting UAC"
Write-Verbose "$currentAct ..."
Write-Progress -Activity $overallAct -Status $currentAct -Id 11
# Disable for admins...
New-ItemProperty -Path "$LMWinCurrent\Policies\System" -Name ConsentPromptBehaviorAdmin -PropertyType DWord -Value 0 -Force | out-null
# Don't gray out screen when prompted for all users...
New-ItemProperty -Path "$LMWinCurrent\Policies\System" -Name PromptOnSecureDesktop -PropertyType DWord -Value 0 -Force | out-null

# ----------[ First Login Animation ]--------------------------------------------------------------------------------------------------
# (should be added to Unattend.xml instead)
#Write-Verbose "Disabling first time login animation and delay..."
#New-ItemProperty -Path "$LMWinCurrent\Policies\System" -Name DelayedDesktopSwitchTimeout -PropertyType DWord -Value 0 -Force
#New-ItemProperty -Path "$LMWinCurrent\Policies\System" -Name EnableFirstLogonAnimation -PropertyType DWord -Value 0 -Force

# ----------[ Consumer Experience App Shortcuts on Start Menu ]------------------------------------------------------------------------
# (should be added to Unattend.xml instead)
#Write-Verbose "Removing consumer experience shortcuts..."
#New-ItemProperty -Path "$LMPolicyMS\Windows\CloudContent" -Name DisableWindowsConsumerFeatures -PropertyType DWord -Value 1 -Force

# ----------[ Scheduled Tasks ]--------------------------------------------------------------------------------------------------------
[string]$currentAct = "Disabling scheduled tasks"
Write-Verbose "$currentAct ..."
Write-Progress -Activity $overallAct -Status $currentAct -Id 12
$ProgressPreference = "SilentlyContinue"
# Office 365 and 2016 telemetry...
Get-ScheduledTask -TaskPath "\Microsoft\Office\" -TaskName "OfficeTelemetryAgentFallBack2016" | Disable-ScheduledTask | out-null
Get-ScheduledTask -TaskPath "\Microsoft\Office\" -TaskName "OfficeTelemetryAgentLogOn2016" | Disable-ScheduledTask | out-null
# Application experience telemetry...
Get-ScheduledTask -TaskPath "\Microsoft\Windows\Application Experience\" -TaskName "Microsoft Compatibility Appraiser" | Disable-ScheduledTask | out-null
# Customer Experience Improvement Program telemetry (all tasks in paths)....
Get-ScheduledTask -TaskPath "\Microsoft\Windows\AutoCHK\" | Disable-ScheduledTask | out-null
Get-ScheduledTask -TaskPath "\Microsoft\Windows\Customer Experience Improvement Program\" | Disable-ScheduledTask | out-null
# Parental Controls...
Get-ScheduledTask -TaskPath "\Microsoft\Windows\Shell\" -TaskName "FamilySafetyMonitor" | Disable-ScheduledTask | out-null
Get-ScheduledTask -TaskPath "\Microsoft\Windows\Shell\" -TaskName "FamilySafetyMonitorToastTask" | Disable-ScheduledTask | out-null
Get-ScheduledTask -TaskPath "\Microsoft\Windows\Shell\" -TaskName "FamilySafetyRefreshTask" | Disable-ScheduledTask | out-null
# File Indexer...
Get-ScheduledTask -TaskPath "\Microsoft\Windows\Shell\" -TaskName "IndexerAutomaticMaintenance" | Disable-ScheduledTask | out-null
# (should be added to Unattend.xml instead)
# Automatic Driver Install...
#Get-ScheduledTask -TaskPath "\Microsoft\Windows\UpdateOrchestrator\" -TaskName "Driver Install" | Disable-ScheduledTask
$ProgressPreference = "Continue"

# ----------[ Windows Explorer Settings ]----------------------------------------------------------------------------------------------
[string]$currentAct = "Modifying file explorer settings"
Write-Verbose "$currentAct ..."
Write-Progress -Activity $overallAct -Status $currentAct -Id 13
if (Test-Path "$DEPLOYROOT\Scripts\setbitbin.vbs")
{
	Copy-Item "$DEPLOYROOT\Scripts\setbitbin.vbs" -Destination "$env:SYSTEMROOT\setbitbin.vbs" -Force | out-null
}
# File Explorer settings for current user...
New-ItemProperty -Path "$CUExpAdv" -Name DontPrettyPath -PropertyType DWord -Value 1 -Force | out-null
New-ItemProperty -Path "$CUExpAdv" -Name Hidden -PropertyType DWord -Value 1 -Force | out-null
New-ItemProperty -Path "$CUExpAdv" -Name HideDrivesWithNoMedia -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$CUExpAdv" -Name HideFileExt -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$CUExpAdv" -Name HideIcons -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$CUExpAdv" -Name NavPaneExpandToCurrentFolder -PropertyType DWord -Value 1 -Force | out-null
New-ItemProperty -Path "$CUExpAdv" -Name ShowSuperHidden -PropertyType DWord -Value 1 -Force | out-null
New-ItemProperty -Path "$CUExpAdv" -Name ShowSyncProviderNotifications -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$CUExpAdv" -Name Start_ShowMyGames -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$CUExpAdv" -Name Start_SearchFiles -PropertyType DWord -Value 1 -Force | out-null
New-ItemProperty -Path "$CUWinCurrent\Explorer" -Name link -PropertyType DWord -Value 0x00000000 -Force | out-null
New-ItemProperty -Path "$CUWinCurrent\Explorer" -Name NoSaveSettings -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$CUWinCurrent\Explorer" -Name NoThemesTab -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$CUWinCurrent\Explorer" -Name StartMenuLogOff -PropertyType DWord -Value 1 -Force | out-null
New-ItemProperty -Path "$CUWinCurrent\Policies\Explorer" -Name NoDrives -PropertyType DWord -Value 0 -Force | out-null
New-Item -Path "$CUWinCurrent" -Name RunOnce -Force | out-null
New-ItemProperty -Path "$CUWinCurrent\RunOnce" -Name SetBitBin -PropertyType String -Value "CScript.exe $env:SYSTEMROOT\setbitbin.vbs" -Force | out-null
New-ItemProperty -Path "$CUControl\Accessibility\StickyKeys" -Name Flags -PropertyType String -Value "506" -Force | out-null
New-ItemProperty -Path "$CUControl\Desktop" -Name MenuShowDelay -PropertyType String -Value "50" -Force | out-null
# File Explorer settings for default user (each subsequent user that logs in)...
New-ItemProperty -Path "$UExpAdv" -Name DontPrettyPath -PropertyType DWord -Value 1 -Force | out-null
New-ItemProperty -Path "$UExpAdv" -Name Hidden -PropertyType DWord -Value 1 -Force | out-null
New-ItemProperty -Path "$UExpAdv" -Name HideDrivesWithNoMedia -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$UExpAdv" -Name HideFileExt -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$UExpAdv" -Name HideIcons -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$UExpAdv" -Name NavPaneExpandToCurrentFolder -PropertyType DWord -Value 1 -Force | out-null
New-ItemProperty -Path "$UExpAdv" -Name ShowSuperHidden -PropertyType DWord -Value 1 -Force | out-null
New-ItemProperty -Path "$UExpAdv" -Name ShowSyncProviderNotifications -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$UExpAdv" -Name Start_ShowMyGames -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$UExpAdv" -Name Start_SearchFiles -PropertyType DWord -Value 1 -Force | out-null
New-ItemProperty -Path "$UWinCurrent\Explorer" -Name link -PropertyType DWord -Value 0x00000000 -Force | out-null
New-ItemProperty -Path "$UWinCurrent\Explorer" -Name NoSaveSettings -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$UWinCurrent\Explorer" -Name NoThemesTab -PropertyType DWord -Value 0 -Force | out-null
New-ItemProperty -Path "$UWinCurrent\Explorer" -Name StartMenuLogOff -PropertyType DWord -Value 1 -Force | out-null
New-Item -Path "$UWinCurrent" -Name Policies -Force | out-null
New-Item -Path "$UWinCurrent\Policies" -Name Explorer -Force | out-null
New-ItemProperty -Path "$UWinCurrent\Policies\Explorer" -Name NoDrives -PropertyType DWord -Value 0 -Force | out-null
New-Item -Path "$UWinCurrent" -Name RunOnce -Force | out-null
New-ItemProperty -Path "$UWinCurrent\RunOnce" -Name SetBitBin -PropertyType String -Value "CScript.exe C:\setbitbin.vbs" -Force | out-null
New-ItemProperty -Path "$UControl\Accessibility\StickyKeys" -Name Flags -PropertyType String -Value "506" -Force | out-null
New-ItemProperty -Path "$UControl\Desktop" -Name MenuShowDelay -PropertyType String -Value "50" -Force | out-null

# ----------[ Unload Default User from Registry ]--------------------------------------------------------------------------------------
[string]$currentAct = "Saving and unloading default user hive"
Write-Verbose "$currentAct ..."
Write-Progress -Activity $overallAct -Status $currentAct -Id 14
[gc]::collect() | out-null
Start-Sleep -Seconds 5
reg.exe UNLOAD "HKU\DefaultUser" | out-null

# ----------[ Services ]---------------------------------------------------------------------------------------------------------------
[string]$currentAct = "Disabling services"
Write-Verbose "$currentAct ..."
New-ItemProperty -Path "$LMControlServices\xbgm" -Name Start -PropertyType DWord -Value 0x00000004 -Force | out-null
# Warning: dmwappushsvc is required for MDT to function, so only disable this after deployment (at the end of your task sequence)
$i = 0
$svcs=@(
	"ALG"				# Application Layer Gateway Service (only needed for Internet Connection Sharing)
	"DiagTrack"			# Connected User Experiences and Telemetry
	"DoSvc"				# Delivery Optimization
	"Fax"				# Fax
	"icssvc"			# Windows Mobile Hotspot Service
	"lfsvc"				# Geolocation Service
	"MapsBroker"		# Download Maps Manager (Bing Maps)
	"PeerDistSvc"		# BranchCache (used for peer-to-peer Windows Update sharing)
	"PhoneSvc"			# Phone Service
	"RetailDemo"		# Retail Demo Service
	"SCardSvr"			# Smart Card
	"ScDeviceEnum"		# Smart Card Device Enumeration Service
	"scfilter"			# Smart Card PnP Class Filter Driver
	"SCPolicySvc"		# Smart Card Removal Policy
	"SEMgrSvc"			# Payments and NFC/SE Manager
	"SharedAccess"		# Internet Connection Sharing (ICS)
	"SmsRouter"			# Microsoft Windows SMS Router Service
	"wisvc"				# Windows Insider Service
	"WMPNetworkSvc"		# Windows Media Player Network Sharing Service
	"WpcMonSvc"			# Parental Controls
	"WwanSvc"			# WWAN AutoConfig
	#"xbgm"				# Xbox Game Monitoring - can't disable through management, must disable in registry
	"XblAuthManager"	# Xbox Live Auth Manager
	"XblGameSave"		# Xbox Live Game Save
	"xboxgip"			# Xbox Game Input Protocol Driver
	"XboxGipSvc"		# Xbox Accessory Management Service
)
foreach ($svc in $svcs)
{
	$i++
	Write-Verbose "`tDisabling $svc ..."
	Write-Progress -Activity $currentAct -Status "Disabling $svc" -Id 15 -PercentComplete (($i / $svcs.count) * 100)
	$ProgressPreference = "SilentlyContinue"
	Stop-Service -Name $svc -Force | out-null # not necessary on services set to manual startup
	Set-Service -Name $svc -StartupType Disabled | out-null
	$ProgressPreference = "Continue"
}

# ----------[ Apps & App Provisioning (Windows 10 Version 1803) ]----------------------------------------------------------------------
[string]$currentAct = "Removing built-in apps and their provisioning"
Write-Verbose "$currentAct :"
$i = 0
$apps=@(
	"Microsoft.Advertising.Xaml"
	"Microsoft.BingFinance"
	"Microsoft.BingNews*"
	"Microsoft.BingSports*"
	"Microsoft.BingWeather"
	"Microsoft.CommsPhone"
	"Microsoft.ConnectivityStore"
	"Microsoft.DesktopAppInstaller"
	"Microsoft.FreshPaint"
	"Microsoft.GetHelp"
	"Microsoft.Getstarted"
	"Microsoft.Messaging"
	"Microsoft.MicrosoftOfficeHub"
	"Microsoft.MicrosoftSolitaireCollection"
	"Microsoft.MinecraftUWP"
	"Microsoft.Office.OneNote"
	"Microsoft.OneConnect"
	"Microsoft.Office.Sway"
	"Microsoft.People"
	"Microsoft.Print3D"
	#"Microsoft.SkypeApp"
	"Microsoft.StorePurchaseApp"
	"Microsoft.SurfaceHub"
	"Microsoft.Wallet"
	"Microsoft.windowscommunicationsapps"
	"Microsoft.WindowsCamera"
	"Microsoft.WindowsFeedbackHub"
	"Microsoft.WindowsMaps"
	"Microsoft.WindowsPhone"
	"Microsoft.WindowsSoundRecorder"
	#"Microsoft.Windows.CloudExperienceHost" #can't remove at all, must disable from registry
	#"Microsoft.Windows.ContentDeliveryManager" #can't remove here, must disable from registry
	#"Microsoft.Windows.Cortana" #can't remove at all, must disable from registry
	#"Microsoft.Windows.HolographicFirstRun" #can't remove here, must disable from registry
	#"Microsoft.Windows.ParentalControls" #can't remove here, must disable feature with DISM or from registry
	#"Microsoft.Windows.PeopleExperienceHost" #can't remove here, must disable feature with DISM or from registry
	"Microsoft.Windows.Phone"
	"Microsoft.XboxApp"
	"Microsoft.Xbox.TCUI"
	"Microsoft.XboxGameOverlay"
	#"Microsoft.XboxGameCallableUI" #can't remove here, must disable feature with DISM or from registry
	"Microsoft.XboxGamingOverlay"
	"Microsoft.XboxIdentityProvider"
	"Microsoft.XboxSpeechToTextOverlay"
	"Microsoft.ZuneMusic"
	"Microsoft.ZuneVideo"
	#"Windows.CBSPreview"  #can't remove here, must disable feature with DISM or from registry
	"ClearChannelRadioDigital.iHeartRadio"
	"Fitbit.FitbitCoach"
	"Flipboard.Flipboard"
	"king.com.CandyCrushSaga*"
	"king.com.CandyCrushSodaSaga*"
	"ShazamEntertainmentLtd.Shazam"
	"TheNewYorkTimes.NYTCrossword"
	"ThumbmunkeysLtd.PhototasticCollage"
	"*.ACGMEDIAPLAYER"
	"*DrawboardPDF*"
	"*.HiddenCityMysteryofShadows*"
	"*Minecraft*"
	"*MSNSports*"
	"*.PicsArt-PhotoStudio"
	"*.Plex"
	"*RoyalRevolt*"
	"*.Twitter"
)
foreach ($app in $apps)
{
	$i++
	Write-Verbose "`tRemoving $app ..."
	Write-Progress -Activity $currentAct -Status "Removing $app" -Id 16 -PercentComplete (($i / $apps.count) * 100)
	$ProgressPreference = "SilentlyContinue"
	Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage | out-null
	Get-AppXProvisionedPackage -Online | where DisplayName -EQ $app | Remove-AppxProvisionedPackage -Online | out-null
	[string]$appPath="$Env:LOCALAPPDATA\Packages\$app*"
	Remove-Item $appPath -Recurse -Force | out-null
	$ProgressPreference = "Continue"
}

# ----------[ VC++ Redistribute Temporary Files ]--------------------------------------------------------------------------------------
[string]$currentAct = "Deleting temporary files from Visual C redistribute installers"
Write-Verbose "$currentAct :"
Write-Progress -Activity $overallAct -Status $currentAct -Id 17
if (Test-Path "$env:SYSTEMDRIVE\eula.????.txt") { Remove-Item -Path "$env:SYSTEMDRIVE\eula.????.txt" -Force | out-null }
if (Test-Path "$env:SYSTEMDRIVE\globdata.ini") { Remove-Item -Path "$env:SYSTEMDRIVE\globdata.ini" -Force | out-null }
if (Test-Path "$env:SYSTEMDRIVE\install.ex") { Remove-Item -Path "$env:SYSTEMDRIVE\install.exe" -Force | out-null }
if (Test-Path "$env:SYSTEMDRIVE\install.ini") { Remove-Item -Path "$env:SYSTEMDRIVE\install.ini" -Force | out-null }
if (Test-Path "$env:SYSTEMDRIVE\install.res.????.dll") { Remove-Item -Path "$env:SYSTEMDRIVE\install.res.????.dll" -Force | out-null }
if (Test-Path "$env:SYSTEMDRIVE\VC_RED.???") { Remove-Item -Path "$env:SYSTEMDRIVE\VC_RED.???" -Force | out-null }
if (Test-Path "$env:SYSTEMDRIVE\vcredist.bmp") { Remove-Item -Path "$env:SYSTEMDRIVE\vcredist.bmp" -Force | out-null }
if ((Test-Path "$env:SYSTEMDRIVE\msdia80.dll") -and (Test-Path "$env:COMMONPROGRAMFILES\microsoft shared\VC"))
{
	Move-Item -Path "$env:SYSTEMDRIVE\msdia80.dll" -Destination "$env:COMMONPROGRAMFILES\microsoft shared\VC" -Force | out-null
	RegSvr32.exe "$env:COMMONPROGRAMFILES\microsoft shared\VC\msdia80.dll" /s | out-null
}

# ----------[ User Temporary Files ]---------------------------------------------------------------------------------------------------
[string]$currentAct = "Deleting current user's temporary files"
Write-Verbose "$currentAct :"
Write-Progress -Activity $overallAct -Status $currentAct -Id 18
if (Test-Path "$env:TEMP") { Remove-Item "$env:TEMP\*" -Recurse -Force | out-null }
else { New-Item "$env:TEMP" -Force }

# ----------[ System Temporary Files ]-------------------------------------------------------------------------------------------------
[string]$currentAct = "Deleting the system's temporary files"
Write-Verbose "$currentAct :"
Write-Progress -Activity $overallAct -Status $currentAct -Id 19
if (Test-Path "$env:SYSTEMROOT\Temp") { Remove-Item "$env:SYSTEMROOT\Temp" -Recurse -Force | out-null }
else { New-Item "$env:SYSTEMROOT\Temp" -ItemType Directory -Force  | out-null }

# ----------[ Hibernation ]------------------------------------------------------------------------------------------------------------
[string]$currentAct = "Disabling hibernation"
Write-Verbose "$currentAct :"
Write-Progress -Activity $overallAct -Status $currentAct -Id 20
powercfg.exe /hibernate off | out-null

# ----------[ File Indexing ]----------------------------------------------------------------------------------------------------------
[string]$currentAct = "Removing file indexing attributes"
Write-Verbose "$currentAct :"
Write-Progress -Activity $overallAct -Status $currentAct -Id 21
ATTRIB.EXE -I C:\*.* /S /D | out-null

# ----------[ Set Sound Volume ]-------------------------------------------------------------------------------------------------------
[string]$currentAct = "Setting sound volume"
Write-Verbose "$currentAct :"
Write-Progress -Activity $overallAct -Status $currentAct -Id 22
Add-Type -TypeDefinition @'
using System.Runtime.InteropServices;
[Guid("5CDF2C82-841E-4546-9722-0CF74078229A"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IAudioEndpointVolume
{
	int f(); int g(); int h(); int i(); // f() & g() are not used
	int SetMasterVolumeLevelScalar(float fLevel, System.Guid pguidEventContext);
	int j();
	int GetMasterVolumeLevelScalar(out float pfLevel);
	int k(); int l(); int m(); int n();
	int SetMute([MarshalAs(UnmanagedType.Bool)] bool bMute, System.Guid pguidEventContext);
	int GetMute(out bool pbMute);
}
[Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDevice
{
	int Activate(ref System.Guid id, int clsCtx, int activationParams, out IAudioEndpointVolume aev);
}
[Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDeviceEnumerator
{
	int f(); // not used
	int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice endpoint);
}
[ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")] class MMDeviceEnumeratorComObject { }
public class Audio
{
	static IAudioEndpointVolume Vol()
	{
		var enumerator = new MMDeviceEnumeratorComObject() as IMMDeviceEnumerator;
		IMMDevice dev = null;
		IAudioEndpointVolume epv = null;
		Marshal.ThrowExceptionForHR(enumerator.GetDefaultAudioEndpoint(/*eRender*/ 0, /*eMultimedia*/ 1, out dev));
		var epvid = typeof(IAudioEndpointVolume).GUID;
		Marshal.ThrowExceptionForHR(dev.Activate(ref epvid, /*CLSCTX_ALL*/ 23, 0, out epv));
		return epv;
	}
	public static float Volume
	{
		get { float v = -1; Marshal.ThrowExceptionForHR(Vol().GetMasterVolumeLevelScalar(out v)); return v; }
		set { Marshal.ThrowExceptionForHR(Vol().SetMasterVolumeLevelScalar(value, System.Guid.Empty)); }
	}
	public static bool Mute
	{
		get { bool mute; Marshal.ThrowExceptionForHR(Vol().GetMute(out mute)); return mute; }
		set { Marshal.ThrowExceptionForHR(Vol().SetMute(value, System.Guid.Empty)); }
	}
}
'@
[Audio]::Volume  = 0.05 # 5% volume
#[Audio]::Mute = $true

# ----------[ Windows Features & Updates ]---------------------------------------------------------------------------------------------
[string]$currentAct = "Install Windows Features & Updates"
# Disable Windows Update
Write-Verbose "`tDisabling Windows Update ..."
Write-Progress -Activity $currentAct -Status "Disabling Windows Update ..." -Id 23
New-Item -Path "$LMPolicyMS\Windows" -Name WindowsUpdate -Force | out-null
New-Item -Path "$LMPolicyMS\Windows\WindowsUpdate" -Name AU -Force | out-null
New-ItemProperty -Path "$LMPolicyMS\Windows\WindowsUpdate\AU" -Name NoAutoUpdate -PropertyType DWord -Value 1 -Force | out-null
# Windows Features
Write-Verbose "`tAdding .NET 3.5 Windows Feature ..."
Write-Progress -Activity $currentAct -Status "Adding .NET 3.5 Windows Feature ..." -Id 24
$ProgressPreference = "SilentlyContinue"
Enable-WindowsOptionalFeature -Online -FeatureName NetFx3 -All -LimitAccess -Source $featurePath -NoRestart -LogPath $env:TEMP\dism_feature.log | out-null
$ProgressPreference = "Continue"
# Manual Windows Update
Write-Verbose "`tGathering & Installing Windows Updates ..."
Write-Progress -Activity $currentAct -Status "Gathering & Installing Windows Updates ..." -Id 25
Install-Module -Name PSWindowsUpdate -SkipPublisherCheck -Force | out-null
Get-WindowsUpdate -IgnoreReboot -AcceptAll -IgnoreUserInput -Install -NotKBArticleID "KB4100347" -NotTitle "preview" -WindowsUpdate

# ----------[ IP & Host Name ]---------------------------------------------------------------------------------------------------------
[string]$currentAct1 = "Computer Name: $env:ComputerName"
[string]$ipv4 = (Test-Connection -ComputerName $env:ComputerName -Count 1).IPV4Address.IPAddressToString
[string]$currentAct2 = "IP: $ipv4"
Write-Verbose "`n"
Write-Verbose "$currentAct1" -ForegroundColor Cyan
Write-Verbose "$currentAct2"
Write-Verbose "`n"
Write-Progress -Activity "Finalize Windows 10 Script Complete" -Status "Complete! $currentAct1 -- $currentAct2"
Start-Sleep -Seconds 10

exit
