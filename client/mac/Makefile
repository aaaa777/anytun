CONFIG_DIR :=
TEMPLATE_CONFIG_DIR := ../configs/anytun

# for brew install
tarball-src: .FORCE clean build-directory Anytun.hosts BypassDomains.txt client-config.json
	@tar -czvf build/tarball-src.tar.gz \
		src/anytun.sh \
		src/anytund.sh \
		Makefile \
		-C build \
		Anytun.hosts \
		BypassDomains.txt \
		client-config.json

build: .FORCE clean build-directory anytun anytund Anytun.hosts BypassDomains.txt client-config.json
	@tar -czvf build/anytun.tar.gz \
		-C build \
		Anytun.hosts \
		BypassDomains.txt \
		client-config.json \
		anytun \
		anytund
.FORCE:

build-directory:
	@mkdir -p build
	@echo "CONFIG_DIR: $(CONFIG_DIR)"
	@echo "TEMPLATE_CONFIG_DIR: $(TEMPLATE_CONFIG_DIR)"

anytun:
	@if [ -z $(CONFIG_DIR) ]; then echo "CONFIG_DIR is not set"; exit 1; fi
	@echo "#!/bin/sh" > build/anytun
	@cpp --traditional-cpp -C -P \
		-DMACRO_ANYTUN_CONFIG_DIR=${CONFIG_DIR} \
		src/anytun.sh 1>> build/anytun || echo 'built anytun'
	@chmod +x build/anytun

anytund:
	@if [ -z $(CONFIG_DIR) ]; then echo "CONFIG_DIR is not set"; exit 1; fi
	@echo "#!/bin/sh" > build/anytund
	@cpp --traditional-cpp -C -P \
		-DMACRO_ANYTUN_CONFIG_DIR=${CONFIG_DIR} \
		src/anytund.sh 1>> build/anytund || echo 'built anytund'
	@chmod +x build/anytund

Anytun.hosts:
	@cp ${TEMPLATE_CONFIG_DIR}/Anytun.hosts build/

BypassDomains.txt:
	@cp ${TEMPLATE_CONFIG_DIR}/BypassDomains.txt build/

client-config.json:
	@cp ${TEMPLATE_CONFIG_DIR}/client-config.json build/

install:
	@echo "not implemented"

clean: 
	@rm -rf build
