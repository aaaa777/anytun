#!/bin/bash
SCRIPT_DIR=$(dirname "$0")
mkdir -p $SCRIPT_DIR/build
cd $SCRIPT_DIR/build

# TODO: makefile化
mkdir -p tun2socks/arm64
curl -L https://github.com/xjasonlyu/tun2socks/releases/download/v2.5.2/tun2socks-darwin-arm64.zip -o tun2socks.zip
unzip tun2socks -d tun2socks/arm64
mv tun2socks/arm64/tun2socks-darwin-arm64 tun2socks/arm64/tun2socks
rm tun2socks.zip

cp ../src/anytun.sh .
cp ../src/anytund.sh .

cp ../../configs/anytun/Anytun.hosts .
cp ../../configs/anytun/BypassDomains.txt .
cp ../../configs/anytun/client-config.json .

# cp ../../configs/v2ray/config.json .
# cp ../../configs/coredns/Corefile .
cp ../../configs/anytun/client-config.json .

# tarball
tar -czvf anytun.tar.gz anytun.sh anytund.sh launch_anytund.sh install_anytun.sh tun2socks/arm64/tun2socks Anytun.hosts BypassDomains.txt client-config.json