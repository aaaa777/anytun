#!/bin/bash

# 現在のWiFi SSID名を取得する関数
get_current_wifi_ssid() {
    /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | awk '/ SSID:/ {print $2}'
}

# プロキシ設定を変更する関数
set_proxy_settings() {
    local network_service="Wi-Fi"
    local proxy_host="$1"
    local proxy_port="$2"
    
    if [ -z "$proxy_host" ] || [ -z "$proxy_port" ]; then
        # プロキシをオフにする
        networksetup -setwebproxystate "$network_service" off
        networksetup -setsecurewebproxystate "$network_service" off
        echo "プロキシ設定をオフにしました"
    else
        # HTTPプロキシを設定
        networksetup -setwebproxy "$network_service" "$proxy_host" "$proxy_port"
        # HTTPSプロキシを設定
        networksetup -setsecurewebproxy "$network_service" "$proxy_host" "$proxy_port"
        echo "プロキシを設定しました: $proxy_host:$proxy_port"
    fi
}

# メイン処理
while true; do
    SSID=$(get_current_wifi_ssid)
    
    case "$SSID" in
        "Office_WiFi")
            # オフィスWiFiに接続時のプロキシ設定
            set_proxy_settings "proxy.office.example.com" "8080"
            ;;
        "Home_WiFi")
            # 自宅WiFiに接続時はプロキシなし
            set_proxy_settings "" ""
            ;;
        *)
            # その他のネットワークではプロキシなし
            set_proxy_settings "" ""
            ;;
    esac
    
    
    # 5秒待機してから再チェック
    sleep 5
done
