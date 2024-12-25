#!/bin/bash

main() {
    INTERFACE="en0"
    site_ip=""
    dns_ip=""
    if_ip=""

    while true; do
        latest_if_ip=$(ifconfig $INTERFACE | grep 'inet' | awk '{print $2}')
        latest_dns_ip=$(scutil --dns | grep 'nameserver\[[0-9]*\]' | awk '{print $3}' | head -n 1)

        # ipが変わったら
        if [[ "$latest_if_ip" != "$if_ip" ]]; then
            echo "ip is changed"
            # DNSがcisco umbrellaかどうかを確認する
            latest_site_ip=$(dig internetbadguys.com +short +time=1 2> /dev/null)
            if [[ "$latest_site_ip" != "$site_ip" ]]; then
                # cisco umbrellaの場合このサイトはデフォルトで固定のIPを返す
                if [[ "146.112.61.108" == "$latest_site_ip" ]]; then
                    # anytunを起動する
                    echo "cisco umbrella detected"
                else
                    # anytunを停止する
                    echo "network is clean"
                fi
            fi
        fi
        site_ip="$latest_site_ip"
        if_ip="$latest_if_ip"
        sleep 1
    done
}

main
