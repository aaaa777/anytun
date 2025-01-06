#!/bin/zsh
# root required
# TODO: Cとして書いてもいいのでは？

# echo "you cant run this script directly. please run \`make build && cd build && ./anytun\`" # anytun: remove_after_build
# exit 1 # anytun: remove_after_build
# SCRIPT_DIR=$(dirname "$0")
# cd $SCRIPT_DIR

CONFIG_DIR=MACRO_ANYTUN_CONFIG_DIR # anytun: set_config_dir

kill-anytund() {
    pkill -f anytund
}

# check-valiables() {
#     if [[ -z "$CONFIG_DIR" ]]; then
#         echo "CONFIG_DIR is not set"
#         exit 1
#     fi
# }

get-if-data() {
    ifconfig -u
}

get-host-ip() {
    ifconfig en0 | grep 'inet' | awk '{print $2}'
}

get-host-dhcp-dns() {
    ipconfig getpacket en0 | grep 'domain_name_server' | awk -F'[{}]' '{print $2}' | awk -F', ' '{print $1}'
}

get-host-default-dns() {
    scutil --dns | grep 'nameserver\[[0-9]*\]' | awk '{print $3}' | head -n 1
}

get-anytun-dns-override-type() {
    cat $CONFIG_DIR/client-config.json | jq -r '.dns.override_type'
}

is-cisco-umbrella() {
    if [[ "$(dig @$latest_dns_ip internetbadguys.com +short +time=1 2> /dev/null)" == "146.112.61.108" ]]; then
        echo 1
    else
        echo 0
    fi
}

main() {
    if [[ $1 != "serve" ]]; then
        echo "you cant run this script directly."
        exit 1
    fi
    
    kill-anytund
    INTERFACE="en0"
    site_ip=""
    dns_ip=""
    # if_ip=""
    if_data=""
    is_cisco_umbrella=0

    while true; do
        # TODO: client-config.jsonから判定条件を分岐できるようにする
        latest_if_data=$(get-if-data)
        # latest_if_ip=$(get-host-ip)
        # $(get-anytun-dns-override-type)

        # if構成が変わったタイミングでチェックを行う
        is_cisco_umbrella=$(is-cisco-umbrella)
        if [[ "$latest_if_data" != "$if_data" ]]; then
            echo "interface change detected"
            latest_dns_ip=$(get-host-dhcp-dns)
            echo "new dns ip address: $latest_dns_ip"
            # DNSがcisco umbrellaかどうかを確認する
            latest_site_ip=$(dig @$latest_dns_ip internetbadguys.com +short +time=1 2> /dev/null)
            if [[ "$latest_site_ip" != "$site_ip" ]]; then
                # cisco umbrellaの場合このサイトはデフォルトで固定のIPを返す
                if [[ "146.112.61.108" == "$latest_site_ip" ]]; then
                    # anytunを起動する
                    echo "cisco umbrella detected"
                    eval "anytun start"
                else
                    # anytunを停止する
                    echo "network is clean"
                    eval "anytun stop"
                fi
            fi
            site_ip="$latest_site_ip"
            # if_ip="$latest_if_ip"
            if_data="$latest_if_data"
        fi
        sleep 1
    done
}

main $@
