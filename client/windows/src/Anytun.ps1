<# Anytun.exeは各種設定ファイルのビルドやプロセスの管理を行う #>

param(
    [Parameter(HelpMessage="Stop anytun service")]
    [switch]$Stop,

    [Parameter(HelpMessage="Start anytun service")]
    [switch]$Start
)

$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = $(Split-Path -Parent $scriptPath)

function Stop-Anytun {
    Stop-Process -Name anytun -Force -ErrorAction SilentlyContinue
    Stop-Process -Name v2ray -Force -ErrorAction SilentlyContinue
    Stop-Process -Name tun2socks -Force -ErrorAction SilentlyContinue
    Stop-Process -Name coredns -Force -ErrorAction SilentlyContinue
}

function Restart-V2ray {
    Stop-Process -Name v2ray -Force -ErrorAction SilentlyContinue
    Start-Sleep 1
    $v2ray = Start-Process -FilePath ".\v2ray\amd64\v2ray.exe" -ArgumentList "run --config config.json" -WindowStyle Hidden -PassThru
    <# $v2ray.WaitForExit() #>
    return $v2ray
}

function Restart-Tun2Socks {
    Stop-Process -Name tun2socks -Force -ErrorAction SilentlyContinue
    $anytun = Start-Process -FilePath ".\tun2socks\amd64\tun2socks.exe" -ArgumentList "-device", "tun://Anytun", "-proxy", "socks5://127.0.77.1:3002" -WindowStyle Hidden -PassThru
    Start-Sleep -Seconds 5
    $startTime = Get-Date
    <# while ($null -eq (Get-NetAdapter -Name Anytun -ErrorAction SilentlyContinue)) {
        Start-Sleep -Seconds 1
        
        if ((New-TimeSpan -Start $startTime -End (Get-Date)).TotalSeconds -ge 10) {
            Write-Host "NIC Anytun not found"
            break
        }
    } #>

    Write-Output "setting ip address"
    netsh interface ipv4 set address name=Anytun source=static addr=198.19.0.1 mask=255.254.0.0
    Write-Output "removing broadcast ip routing"
    netsh interface ipv4 del route prefix=255.255.255.255/32 interface=Anytun
    <# Write-Output "removing network broadcast ip routing"
    netsh interface ipv4 del route prefix=198.19.255.255/32  interface=Anytun #>
    return $anytun
}

function Restart-Coredns {
    Stop-Process -Name coredns -Force -ErrorAction SilentlyContinue
    <#Write-Output "registering ip address"
    netsh interface ipv4 add address $loopbackIfIdx 198.19.0.53/15
    Start-Sleep 2 #>
    Write-Output "starting coredns"
    $coredns = Start-Process -FilePath ".\coredns\amd64\coredns.exe" -WindowStyle Hidden -PassThru
    Start-Sleep 2
    Write-Output "setting dns server"
    netsh interface ipv4 set dns name=Anytun source=static addr=127.0.77.53 register=primary
    Write-Output "modifying interface metric"
    netsh interface ipv4 set interface interface=Anytun metric=0
    Write-Output "modifying route metric"
    netsh interface ipv4 set route prefix=127.0.77.53/32 interface=Anytun metric=0
    <# Write-Output "modifying lan dns metric"
    netsh interface ipv4 set route prefix=10.10.1.201/32 metric=300 #>

    return $coredns
}

function Build-Corefile{
    param (
        [string] $domains_line
    )

    return "
. {
    bind 127.0.77.53
    forward . 10.10.1.201
    hosts anytun.hosts
    cache 600
}

$domains_line {
    bind 127.0.77.53
    forward . 127.0.77.52
    cache 10
}
"
}

function Get-CurrentV2rayConfig {
    $jsonFilePath = "config.json"
}

function Set-AnytunConfigs {

    <# Corefile #>
    $resultLines = @()
    Get-Content "BypassDomains.txt" | ForEach-Object {
        if ($_ -match '^\s*#|^\s*$') {
            return
        }
        $resultLines += ($_ -split '\s+' | Where-Object { $_ -ne '' })
    }
    $domains_line = $resultLines -join ' '
    Build-Corefile -domains_line $domains_line | Out-File -FilePath 'Corefile' -Encoding utf8
}

<# メイン処理 #>
function Invoke-Main {
    if ($Stop) {
        Stop-Anytun
        return
    }

    if ($Start) {
        Set-AnytunConfigs
        
        if (Get-Process -Name "v2ray" -ErrorAction SilentlyContinue) {
            $v2ray = Restart-V2ray
        }

        if($null -eq (Get-NetAdapter | Where-Object { $_.Name -eq "Anytun" })) {
            $tun2socks = Restart-Tun2Socks
        }
        
        if (Get-Process -Name "coredns" -ErrorAction SilentlyContinue) {
            $coredns = Restart-Coredns
        }
        return
    }
}

# echo $scriptDir
Invoke-Main
