#!/bin/zsh
# root required
# TODO: Cとして書いてもいいのでは？

# echo "you cant run this script directly. please run \`make build && cd build && ./anytun\`" # anytun: remove_after_build
# exit 1 # anytun: remove_after_build
# SCRIPT_DIR=$(dirname "$0")
# cd $SCRIPT_DIR

CONFIG_DIR=MACRO_ANYTUN_CONFIG_DIR # anytun: set_config_dir
ANYTUN_EXECUTABLE=MACRO_ANYTUN_EXECUTABLE # anytun: set_executable

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

# not implemented yet
get-anytun-dns-override-type() {
    type="$(cat $CONFIG_DIR/client-config.json | jq -r '.dns.override_type')"
    if [[ "$type" == "dhcp" ]]; then
        echo "dhcp"
    elif [[ "$type" == "static" ]]; then
        echo "static"
    else
        echo "default"
    fi
}

is-cisco-umbrella() {
    if [[ "$(dig @$1 internetbadguys.com +short +time=1 2> /dev/null)" == "146.112.61.108" ]]; then
        echo 1
    else
        echo 0
    fi
}

start-anytun() {
    eval "$ANYTUN_EXECUTABLE start"
}

stop-anytun() {
    eval "$ANYTUN_EXECUTABLE stop"
}

main() {
    if [[ $1 != "serve" ]]; then
        echo "you cant run this script directly."
        exit 1
    fi

    if [[ $2 == "--dry" ]]; then
        echo "dry run"
        DRY_RUN=1
    fi

    kill-anytund
    INTERFACE="en0"
    prev_site_ip=""
    prev_dns_ip=""
    # if_ip=""
    prev_if_data=""
    is_cisco_umbrella=0

    while true; do
        # TODO: client-config.jsonから判定条件を分岐できるようにする
        if_data=$(get-if-data)
        # latest_if_ip=$(get-host-ip)
        # $(get-anytun-dns-override-type)

        # if構成が変わったタイミングでチェックを行う
        if [[ "$prev_if_data" != "$if_data" ]]; then
            echo "interface change detected"
            # delay
            sleep 1
            dns_ip=$(get-host-default-dns)
            echo "new dns ip address: $dns_ip"
            # DNSがcisco umbrellaかどうかを確認する
            # site_ip=$(dig @$dns_ip internetbadguys.com +short +time=1 2> /dev/null)
            is_cisco_umbrella=$(is-cisco-umbrella $dns_ip)
            echo "is cisco umbrella: $is_cisco_umbrella"
            echo "DRY_RUN: $DRY_RUN"

            if [[ $DRY_RUN != "1" ]]; then
                if [[ $is_cisco_umbrella == 1 ]]; then
                    # anytunを起動する
                    echo "cisco umbrella detected"
                    start-anytun
                else
                    # anytunを停止する
                    echo "network is clean"
                    stop-anytun
                fi
            else
                echo "skipping anytun start/stop"
            fi
            prev_site_ip="$site_ip"
            # prev_if_ip="$if_ip"
            prev_if_data="$if_data"
        fi
        # interval
        sleep 1
    done
}

main $@
