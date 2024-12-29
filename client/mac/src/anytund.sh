#!/bin/bash
# root required

SCRIPT_DIR=$(dirname "$0")
cd $SCRIPT_DIR
# CONFIG_DIR="../../configs/anytun"

kill-anytund() {
    pkill -f anytund.sh
}

check-valiables() {
    if [[ -z "$CONFIG_DIR" ]]; then
        echo "CONFIG_DIR is not set"
        exit 1
    fi
}

get-if-data() {
    latest_if_data=$(ifconfig -u)
}

get-host-ip() {
    latest_if_ip=$(ifconfig en0 | grep 'inet' | awk '{print $2}')
}

get-host-dhcp-dns() {
    latest_dns_ip=$(ipconfig getpacket en0 | grep 'domain_name_server' | awk -F'[{}]' '{print $2}' | awk -F', ' '{print $1}')
}

get-host-default-dns() {
    latest_dns_ip=$(scutil --dns | grep 'nameserver\[[0-9]*\]' | awk '{print $3}' | head -n 1)
}

get-anytun-dns-override() {
    return $(cat $CONFIG_DIR/client-config.json | jq -r '.dns.override')
}

main() {
    kill-anytund
    check-valiables
    INTERFACE="en0"
    site_ip=""
    dns_ip=""
    # if_ip=""
    if_data=""

    while true; do
        # TODO: client-config.jsonから判定条件を分岐できるようにする
        get-if-data
        # get-host-ip

        # if構成が変わったタイミングでチェックを行う
        if [[ "$latest_if_data" != "$if_data" ]]; then
            echo "interface change detected"
            get-host-dhcp-dns
            echo "new dns ip address: $latest_dns_ip"
            # DNSがcisco umbrellaかどうかを確認する
            latest_site_ip=$(dig @$latest_dns_ip internetbadguys.com +short +time=1 2> /dev/null)
            if [[ "$latest_site_ip" != "$site_ip" ]]; then
                # cisco umbrellaの場合このサイトはデフォルトで固定のIPを返す
                if [[ "146.112.61.108" == "$latest_site_ip" ]]; then
                    # anytunを起動する
                    echo "cisco umbrella detected"
                    eval "CONFIG_DIR=$CONFIG_DIR anytun.sh start"
                else
                    # anytunを停止する
                    echo "network is clean"
                    eval "CONFIG_DIR=$CONFIG_DIR anytun.sh stop"
                fi
            fi
            site_ip="$latest_site_ip"
            # if_ip="$latest_if_ip"
            if_data="$latest_if_data"
        fi
        sleep 1
    done
}

main
