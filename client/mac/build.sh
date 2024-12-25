#!/bin/bash

# TODO: makefile化
mkdir -p build/tun2socks/arm64
curl -L https://github.com/xjasonlyu/tun2socks/releases/download/v2.5.2/tun2socks-darwin-arm64.zip -o build/tun2socks.zip
unzip build/tun2socks -d build/tun2socks/arm64

