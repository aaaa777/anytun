<# OnNetworkChange.exeはネットワークの変更を検出してAnytun.exeを実行する #>

<# メイン処理 #>
$targetNetworkInterface = "Wi-Fi"
$targetSSID = "HIU_WiFi"
$targetDNSSuffix = "rmme.do-johodai.ac.jp"
$targetDNSServerAddress = "10.10.1.201"

$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = $(Split-Path -Parent $scriptPath)

<# 現在のSSIDを取得する関数 #>
function Get-CurrentSSID {
    try {
        $wifi = (netsh wlan show interfaces | Select-String 'SSID' | Select-String -NotMatch 'BSSID').ToString()
        if ($wifi) {
            return ($wifi -split ":")[1].Trim()
        }
    }
    catch {
        return $null
    }
}

<# DNSサフィックスを取得する関数 #>
function Get-DNSSuffix {
    try {
        $dnsSuffix = (Get-DnsClient | Where-Object {$_.InterfaceAlias -eq "Wi-Fi"}).ConnectionSpecificSuffix
        return $dnsSuffix
    }
    catch {
        return $null
    }
}

<# プロキシ設定を変更する関数 #>
function Set-ProxySettings {
    param (
        [bool]$enable,
        [string]$proxyServer = "socks=localhost:3002",
        [string]$ignoreList = "192.168.*;localhost;*.local;*.do-johodai.ac.jp;*.nakajun.net;"
    )
    
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"

    Set-ItemProperty -Path $regPath -Name ProxyEnable -Value ([int]$enable)
    if ($enable) {
        Set-ItemProperty -Path $regPath -Name ProxyServer -Value $proxyServer
        Set-ItemProperty -Path $regPath -Name ProxyOverride -Value $ignoreList
    }
}

function Set-UpAnytun {
    Start-Process -FilePath ".\anytun.exe" -WindowStyle Hidden -PassThru
}

function Set-DownAnytun {
    Start-Process -FilePath ".\anytun.exe" -ArgumentList "-Stop" -WindowStyle Hidden -PassThru
}

<# 指定のDNSのメトリックを低くする関数 #>
# function Change-DNSMetric {
#     param (
#         [string]$interfaceAlias = "Wi-Fi",
#         [string]$dns
#         [int]$metric = 10
#     )
# }

# function Launch-SshSocks5 {
#     $ssh = Start-Process -FilePath "C:\Program Files\Git\usr\bin\ssh.exe" -ArgumentList "-D 3002 -f -C -q -N user@host" -PassThru
#     $ssh.WaitForExit()
# }

$currentSSID = Get-CurrentSSID
$currentDNSSuffix = Get-DNSSuffix

<# SSIDが一致する場合にプロキシを有効化 #>
if (($currentSSID -eq $targetSSID)) {
    Set-UpAnytun
} else {
    Set-DownAnytun
}