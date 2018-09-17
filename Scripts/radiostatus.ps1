#[CmdletBinding()] Param ([Parameter(Mandatory=$true)][ValidateSet('Off', 'On')][string]$WifiStatus)
$WifiStatus = "Off"

Add-Type -AssemblyName System.Runtime.WindowsRuntime
$asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | ? {$_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'})[0]

Function Await($WinRtTask, $ResultType)
{
	$asTask = $asTaskGeneric.MakeGenericMethod($ResultType)
	$netTask = $asTask.Invoke($null, @($WinRtTask))
	$netTask.Wait(-1) | Out-Null
	$netTask.Result
}

[Windows.Devices.Radios.Radio,Windows.System.Devices,ContentType=WindowsRuntime]
[Windows.Devices.Radios.RadioAccessStatus,Windows.System.Devices,ContentType=WindowsRuntime]
Await ([Windows.Devices.Radios.Radio]::RequestAccessAsync()) ([Windows.Devices.Radios.RadioAccessStatus])
$radios = Await ([Windows.Devices.Radios.Radio]::GetRadiosAsync()) ([System.Collections.Generic.IReadOnlyList[Windows.Devices.Radios.Radio]])
$wifi = $radios | ? { $_.Kind -eq 'WiFi' }
[Windows.Devices.Radios.RadioState,Windows.System.Devices,ContentType=WindowsRuntime]

Start-Sleep -Seconds 10
Await ($wifi.SetStateAsync($WifiStatus)) ([Windows.Devices.Radios.RadioAccessStatus])
