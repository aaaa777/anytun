#!/bin/bash

build: .FORCE
	mkdir -p build && \
	cd build && \
	cp ../Makefile . && \
	cp ../src/anytun.sh . && \
	cp ../src/anytund.sh . && \
	cp ../src/launch_anytund.sh . && \
	cp ../src/install_anytun.sh . && \
	cp ../../configs/anytun/Anytun.hosts . && \
	cp ../../configs/anytun/BypassDomains.txt . && \
	cp ../../configs/anytun/client-config.json . && \
	tar -czvf anytun.tar.gz anytun.sh anytund.sh launch_anytund.sh install_anytun.sh Anytun.hosts BypassDomains.txt client-config.json Makefile

.FORCE:

install:
	echo "not implemented"

# もっとスマートに書きたいのだが
install-in-brew:
	ANYTUN_SH=(cat anytun.sh) && \
	ANYTUND_SH=(cat anytund.sh) && \
	sed -i '' 's|CONFIG_DIR=.*|CONFIG_DIR=$(CONFIG_DIR)|' anytun.sh && \
	sed -i '' 's|CONFIG_DIR=.*|CONFIG_DIR=$(CONFIG_DIR)|' anytund.sh && \
	mkdir -p $(CONFIG_DIR) && \
	cp ./Anytun.hosts $(CONFIG_DIR)/Anytun.hosts && \
	cp ./BypassDomains.txt $(CONFIG_DIR)/BypassDomains.txt && \
	cp ./client-config.json $(CONFIG_DIR)/client-config.json
	