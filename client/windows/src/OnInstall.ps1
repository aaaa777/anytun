$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = $(Split-Path -Parent $scriptPath)

function Register-StartupService {
    $serviceName = "Startup"
    $cmdPwd = (Get-Location).Path
    $servicePath = "$pwd\Anytun.exe"
    $serviceAction = New-ScheduledTaskAction -Execute "$servicePath" -WorkingDirectory "$cmdPwd"

    $serviceTrigger = New-ScheduledTaskTrigger -AtStartup
    $serviceSettings = New-ScheduledTaskSettingsSet -Disable -DontStopIfGoingOnBatteries -StartWhenAvailable -Hidden -AllowStartIfOnBatteries
    Register-ScheduledTask -TaskName $serviceName -Action $serviceAction -Trigger $serviceTrigger -Settings $serviceSettings -Force -TaskPath "Microsoft\Windows\Anytun"# -RunLevel Highest 
}

function Register-NetworkChangeEvent {
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

    $serviceSettings = New-ScheduledTaskSettingsSet -DontStopIfGoingOnBatteries -StartWhenAvailable -Hidden -AllowStartIfOnBatteries
    Register-ScheduledTask -TaskName $serviceName -Action $serviceAction -Trigger $serviceTrigger -Settings $serviceSettings -RunLevel Highest -Force -TaskPath "Microsoft\Windows\Anytun"
}

<# function Get-Wintun {
    $zipUrl = "https://www.wintun.net/builds/wintun-0.14.1.zip"

    $tempFolder = "$env:TEMP\TempDownload"
    $extractFolder = "$env:TEMP\ExtractedFiles"
    $destinationFolder = ".\tun2socks"

    New-Item -ItemType Directory -Path $tempFolder -Force
    New-Item -ItemType Directory -Path $extractFolder -Force

    $zipPath = "$tempFolder\downloaded.zip"
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath

    Expand-Archive -Path $zipPath -DestinationPath $extractFolder -Force

    $fileToCopy = "wintun.dll"
    $fileInZip = "wintun\bin\amd64\wintun.dll"
    $sourcePath = Join-Path $extractFolder $fileInZip
    $destinationPath = Join-Path $destinationFolder $fileToCopy

    New-Item -ItemType Directory -Path $destinationFolder -Force
    Copy-Item -Path $sourcePath -Destination $destinationPath -Force

    Remove-Item -Path $tempFolder -Recurse -Force
    Remove-Item -Path $extractFolder -Recurse -Force
} #>

<# メイン処理 #>
Register-StartupService
Register-NetworkChangeEvent

