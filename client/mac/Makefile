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
