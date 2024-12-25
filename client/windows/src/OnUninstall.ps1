$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = $(Split-Path -Parent $scriptPath)

function Stop-AnytunProcess {
    Stop-Process -Name anytun -Force -ErrorAction SilentlyContinue
    Stop-Process -Name v2ray -Force -ErrorAction SilentlyContinue
    Stop-Process -Name tun2socks -Force -ErrorAction SilentlyContinue
    Stop-Process -Name coredns -Force -ErrorAction SilentlyContinue
}

function Remove-scheduledTask {
    $serviceName = "OnNetworkChange"
    $cmdPwd = (Get-Location).Path
    $servicePath = "$pwd\OnNetworkChange.exe"
    $serviceAction = New-ScheduledTaskAction -Execute "$servicePath" -WorkingDirectory "$cmdPwd"

    $CIMTriggerClass = Get-CimClass -ClassName MSFT_TaskEventTrigger -Namespace Root/Microsoft/Windows/TaskScheduler:MSFT_TaskEventTrigger
    $serviceTrigger = New-CimInstance -CimClass $CIMTriggerClass -ClientOnly
    $serviceTrigger.Subscription = 
@"
<QueryList><Query Id="0" Path="Microsoft-Windows-NetworkProfile/Operational"><Select Path="Microsoft-Windows-NetworkProfile/Operational">*[System[(EventID=4004)]]</Select></Query></QueryList>
"@
    $serviceTrigger.Enabled = $True

    $serviceSettings = New-ScheduledTaskSettingsSet -DontStopIfGoingOnBatteries -StartWhenAvailable -Hidden -AllowStartIfOnBatteries -Disable
    Register-ScheduledTask -TaskName $serviceName -Action $serviceAction -Trigger $serviceTrigger -Settings $serviceSettings -RunLevel Highest -Force -TaskPath "Microsoft\Windows\Anytun"
}

Remove-scheduledTask
Stop-AnytunProcess
