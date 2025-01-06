#!/bin/zsh
# root required
# TODO: Cとして書いてもいいのでは？

# echo "you cant run this script directly. please run \`make build && cd build && ./anytun\`" # anytun: remove_after_build
# exit 1 # anytun: remove_after_build
# SCRIPT_DIR=$(dirname "$0")
# cd $SCRIPT_DIR

CONFIG_DIR=MACRO_ANYTUN_CONFIG_DIR # anytun: set_config_dir
TMP_CONFIG_DIR="/tmp/anytun"

setup-ip() {
    ifconfig lo0 alias 127.0.77.1/32  # socks5(v2ray)
    ifconfig lo0 alias 127.0.77.52/32 # fakedns(v2ray)
    ifconfig lo0 alias 127.0.77.53/32 # coredns
}

setup-route() {
    ifconfig utun77 198.19.0.1/32 broadcast 198.19.0.1 up
    route add -net 198.18/16 198.19.0.1 -ifscope utun77
}

setup-config() {
    mkdir -p "$TMP_CONFIG_DIR"
    build-v2ray-config > "$TMP_CONFIG_DIR/config.json"
    build-coredns-config > "$TMP_CONFIG_DIR/Corefile"
}

stop-services() {
    pkill -f coredns
    pkill -f v2ray
    pkill -f tun2socks
}

start-services() {
    coredns -conf "$TMP_CONFIG_DIR/Corefile" &
    v2ray run -config "$TMP_CONFIG_DIR/config.json" &
    tun2socks -device tun://utun77 -proxy socks5://127.0.77.1:3002 &
}

# for loadbalancing
get-anytun-gateway-servers() {
    cat "$CONFIG_DIR/client-config.json" | jq -r '.gateway.servers'
}

get-anytun-bypass-domains() {
    cat $CONFIG_DIR/BypassDomains.txt | grep -v -e '^#' -e '^$' | uniq | tr '\n' ' '
}



build-v2ray-config() {
    jq -nc --argjson vnext "$(get-anytun-gateway-servers)" '
{
  "//comment//": "これは内部向け自動生成ファイルです。接続先の編集はclient-config.jsonを利用してください。",
  "log": {
    "loglevel": "warning"
  },

  "inbounds": [
    {
      "tag": "socks-inbound",
      "protocol": "socks",
      "listen": "127.0.77.1",
      "port": 3002,
      "settings": {
        "auth": "noauth",
        "udp": true,
        "ip": "127.0.77.1"
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["fakedns"],
        "metadataOnly": false
      }
    },
    {
      "tag": "dns-in",
      "protocol": "dokodemo-door",
      "port": 53,
      "listen": "127.0.77.52",
      "settings": {
        "network": "tcp,udp",
        "address": "fakedns",
        "followRedirect": false
      }
    }
  ],

  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {},
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    },
    {
      "protocol": "dns",
      "tag": "dns-out"
    },
    {
      "protocol": "vmess",
      "settings": {
        "vnext": $vnext
      },
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "wsSettings": {
          "path": "/ws"
        },
        "tlsSettings": {
          "allowInsecure": true
        }
      },
      "tag": "oc-proxy"
    }
  ],

  "routing": {
    "domainStrategy": "AsIs",
    "rules":[
      {
        "type": "field",
        "inboundTag": ["socks-inbound"],
        "ip": [
          "198.19.255.255",
          "255.255.255.255"
        ],
        "outboundTag": "blocked"
      },
      {
        "type": "field",
        "inboundTag": ["dns-in"],
        "outboundTag": "dns-out"
      },
      {
        "type": "field",
        "inboundTag": ["socks-inbound"],
        "outboundTag": "oc-proxy"
      },
      {
        "type": "field",
        "domain": [
          "geosite:category-ads"
        ],
        "outboundTag": "blocked"
      }
    ]
  },

  
  "dns": {
    "fakedns": [
      {
        "ipPool": "198.18.0.0/16",
        "poolSize": 65535
      }
    ],
    "hosts": {
    },
    "disableCache": false,
    "disableFallback": false,
    "disableFallbackIfMatch": false,
    "servers": [
      "fakedns"
    ]
  },

  "policy": {
    "levels": {
      "0": {
        "uplinkOnly": 0,
        "downlinkOnly": 0
      }
    },
    "system": {
      "statsInboundUplink": false,
      "statsInboundDownlink": false,
      "statsOutboundUplink": false,
      "statsOutboundDownlink": false
    }
  }
}
'
}

build-coredns-config() {
    LAN_ROOT_DNS=$(get-anytun-lan-root-dns)
    BYPASS_DOMAINS=$(get-anytun-bypass-domains)
    cat <<EOF
. {
    bind 127.0.77.53
    forward . $LAN_ROOT_DNS
    hosts $CONFIG_DIR/Anytun.hosts
    cache 600
    log
}

$BYPASS_DOMAINS {
    bind 127.0.77.53
    forward . 127.0.77.52
    cache 10
    log
}
EOF
}

main() {
    case $1 in
        start)
            echo "starting anytun services"
            stop-services
            setup-config
            setup-ip
            start-services
            # sleep 1
            setup-route
            ;;
        stop)
            echo "stopping anytun services"
            stop-services
            ;;
        add-server)
            SERVER_ADDRESS=$2
            USER_ID=$3
            ;;
        *)
            echo "Usage: $0 {start|stop}"
            exit 1
            ;;
    esac
}

main $*
