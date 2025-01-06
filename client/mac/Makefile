BREW_BUILD := 0
CONFIG_DIR := /etc/anytun
TEMPLATE_CONFIG_DIR := ../configs/anytun
ANYTUN_EXECUTABLE := anytun

ifeq ($(BREW_BUILD), 1)
CONFIG_DIR := /usr/local/etc/anytun
TEMPLATE_CONFIG_DIR := .
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

.FORCE:

build-directory:
	@mkdir -p build
	@echo "CONFIG_DIR: $(CONFIG_DIR)"
	@echo "TEMPLATE_CONFIG_DIR: $(TEMPLATE_CONFIG_DIR)"

anytun: build-directory
	@if [ -z $(CONFIG_DIR) ]; then echo "CONFIG_DIR is not set"; exit 1; fi
	@sed "s:MACRO_ANYTUN_CONFIG_DIR:${CONFIG_DIR}:g" src/anytun.sh > build/anytun
	@chmod +x build/anytun

anytund: build-directory
	@if [ -z $(CONFIG_DIR) ]; then echo "CONFIG_DIR is not set"; exit 1; fi
	@sed "s:MACRO_ANYTUN_CONFIG_DIR:${CONFIG_DIR}:g" src/anytund.sh | \
		sed "s:MACRO_ANYTUN_EXECUTABLE:${ANYTUN_EXECUTABLE}:g" > build/anytund
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
