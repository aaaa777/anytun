param(
    [Parameter(HelpMessage="Build in CI mode")]
    [switch]$Ci,

    [Parameter(HelpMessage="Set build version(but not implemented)")]
    [string]$Version = "0.0.0",

    [Parameter(HelpMessage="Skip downloads")]
    [switch]$SkipDownload
)

$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = $(Split-Path -Parent $scriptPath)
$appVersion = Get-Content $(Join-Path $scriptDir ".\..\..\VERSION")

echo "build version: $appVersion"

mkdir $(Join-Path $scriptDir ".\build\anytun\amd64") -ErrorAction SilentlyContinue
ps2exe $(Join-Path $scriptDir ".\src\anytun.ps1") $(Join-Path $scriptDir ".\build\anytun\amd64\anytun.exe") -noConsole -noOutput
ps2exe $(Join-Path $scriptDir ".\src\OnInstall.ps1") $(Join-Path $scriptDir ".\build\anytun\amd64\OnInstall.exe") -noConsole -noOutput
ps2exe $(Join-Path $scriptDir ".\src\OnUninstall.ps1") $(Join-Path $scriptDir ".\build\anytun\amd64\OnUninstall.exe") -noConsole -noOutput
ps2exe $(Join-Path $scriptDir ".\src\OnNetworkChange.ps1") $(Join-Path $scriptDir ".\build\anytun\amd64\OnNetworkChange.exe") -noConsole -noOutput

mkdir $(Join-Path $scriptDir ".\build\v2ray\amd64") -ErrorAction SilentlyContinue
Invoke-WebRequest -Uri "https://github.com/v2fly/v2ray-core/releases/download/v5.22.0/v2ray-windows-64.zip" -OutFile $(Join-Path $scriptDir ".\build\v2ray-windows-64.zip")
Expand-Archive -Path $(Join-Path $scriptDir ".\build\v2ray-windows-64.zip") -DestinationPath $(Join-Path $scriptDir ".\build\v2ray\amd64") -Force

mkdir $(Join-Path $scriptDir ".\build\tun2socks\amd64") -ErrorAction SilentlyContinue
Invoke-WebRequest -Uri "https://github.com/xjasonlyu/tun2socks/releases/download/v2.5.2/tun2socks-windows-amd64-v3.zip" -OutFile $(Join-Path $scriptDir ".\build\tun2socks-windows-amd64-v3.zip")
Expand-Archive -Path $(Join-Path $scriptDir ".\build\tun2socks-windows-amd64-v3.zip") -DestinationPath $(Join-Path $scriptDir ".\build\tun2socks\amd64") -Force
Move-Item $(Join-Path $scriptDir ".\build\tun2socks\amd64\tun2socks-windows-amd64-v3.exe") $(Join-Path $scriptDir ".\build\tun2socks\amd64\tun2socks.exe") -Force

mkdir $(Join-Path $scriptDir ".\build\wintun") -ErrorAction SilentlyContinue
Invoke-WebRequest -Uri "https://www.wintun.net/builds/wintun-0.14.1.zip" -OutFile $(Join-Path $scriptDir ".\build\wintun-0.14.1.zip")
Expand-Archive -Path $(Join-Path $scriptDir ".\build\wintun-0.14.1.zip") -DestinationPath $(Join-Path $scriptDir ".\build\wintun") -Force
Move-Item $(Join-Path $scriptDir ".\build\wintun\wintun\bin\amd64\wintun.dll") $(Join-Path $scriptDir ".\build\tun2socks\amd64\wintun.dll") -Force

mkdir $(Join-Path $scriptDir ".\build\coredns\amd64") -ErrorAction SilentlyContinue
Invoke-WebRequest -Uri "https://github.com/coredns/coredns/releases/download/v1.12.0/coredns_1.12.0_windows_amd64.tgz" -OutFile $(Join-Path $scriptDir ".\build\coredns.tgz")
tar -xzf $(Join-Path $scriptDir ".\build\coredns.tgz") -C $(Join-Path $scriptDir ".\build\coredns\amd64")
# Move-Item $(Join-Path $scriptDir ".\build\coredns\amd64\coredns_1.12.0_windows_amd64\coredns.exe") $(Join-Path $scriptDir ".\build\coredns\amd64\coredns.exe") -Force

if ($Ci) {
    iscc.exe /dMyAppVersion="$appVersion" /dMyAppInstallerName="AnytunInstaller" "/SMySignTool=.\signtool.exe sign /v /fd SHA256 /f `$qD:\a\anytun\anytun\GitHubActionsWorkflow.pfx`$q /p $Env:pfxPassphrase /t http://timestamp.comodoca.com/authenticode `$p `$f" $(Join-Path $scriptDir ".\installer.iss")
} else {
    C:\"Program Files (x86)"\"Inno Setup 6"\ISCC.exe /dMyAppVersion=$appVersion /dMyAppInstallerName="AnytunInstaller" $(Join-Path $scriptDir ".\installer.iss")
}
