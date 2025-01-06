BREW_BUILD := 0

ifeq ($(BREW_BUILD), 1)
CONFIG_DIR := /usr/local/etc/anytun
TEMPLATE_CONFIG_DIR := .
else
CONFIG_DIR := /etc/anytun
TEMPLATE_CONFIG_DIR := ../configs/anytun
endif

# for brew install
brew-tarball: .FORCE Anytun.hosts BypassDomains.txt client-config.json
	@tar -czvf build/brew-tarball.tar.gz \
		src/anytun.sh \
		src/anytund.sh \
		Makefile \
		-C build \
		Anytun.hosts \
		BypassDomains.txt \
		client-config.json

build: .FORCE anytun anytund Anytun.hosts BypassDomains.txt client-config.json
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

anytun: build-directory
	@if [ -z $(CONFIG_DIR) ]; then echo "CONFIG_DIR is not set"; exit 1; fi
	@head -1 src/anytun.sh > build/anytun
	@cpp --traditional-cpp -C -P \
		-DMACRO_ANYTUN_CONFIG_DIR=${CONFIG_DIR} \
		src/anytun.sh 1>> build/anytun 2>/dev/null || echo 'built anytun'
	@chmod +x build/anytun

anytund: build-directory
	@if [ -z $(CONFIG_DIR) ]; then echo "CONFIG_DIR is not set"; exit 1; fi
	@head -1 src/anytund.sh > build/anytund
	@cpp --traditional-cpp -C -P \
		-DMACRO_ANYTUN_CONFIG_DIR=${CONFIG_DIR} \
		src/anytund.sh 1>> build/anytund 2>/dev/null || echo 'built anytund'
	@chmod +x build/anytund

Anytun.hosts: build-directory
	@cp ${TEMPLATE_CONFIG_DIR}/Anytun.hosts build/

BypassDomains.txt: build-directory
	@cp ${TEMPLATE_CONFIG_DIR}/BypassDomains.txt build/

client-config.json: build-directory
	@cp ${TEMPLATE_CONFIG_DIR}/client-config.json build/

install:
	@echo "not implemented"

clean: 
	@rm -rf build
