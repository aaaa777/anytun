CONFIG_DIR := 

# for brew install
tarball-src: .FORCE build-directory
	@tar -czvf build/tarball-src.tar.gz \
		./src/anytun.sh \
		./src/anytund.sh \
		../configs/anytun/Anytun.hosts \
		../configs/anytun/BypassDomains.txt \
		../configs/anytun/client-config.json \
		Makefile

build: .FORCE clean build-directory anytun anytund
	@cp ./../configs/anytun/Anytun.hosts build/
	@cp ./../configs/anytun/BypassDomains.txt build/
	@cp ./../configs/anytun/client-config.json build/
	@cp ./Makefile build/
	@tar -czvf build/anytun.tar.gz -C build \
		anytun \
		anytund \
		Anytun.hosts \
		BypassDomains.txt \
		client-config.json
.FORCE:

build-directory:
	@mkdir -p build

anytun:
	@echo "CONFIG_DIR: $(CONFIG_DIR)"
	@if [ -z $(CONFIG_DIR) ]; then echo "CONFIG_DIR is not set"; exit 1; fi
	cpp --traditional-cpp -C -P \
		-DMACRO_ANYTUN_CONFIG_DIR=${CONFIG_DIR} \
		src/anytun.sh 1> build/anytun || echo 'built anytun'
	@chmod +x build/anytun

anytund:
	@echo "CONFIG_DIR: $(CONFIG_DIR)"
	@if [ -z $(CONFIG_DIR) ]; then echo "CONFIG_DIR is not set"; exit 1; fi
	cpp --traditional-cpp -C -P \
		-DMACRO_ANYTUN_CONFIG_DIR=${CONFIG_DIR} \
		src/anytund.sh 1> build/anytund || echo 'built anytund'
	@chmod +x build/anytund

install:
	@echo "not implemented"

clean: 
	@rm -rf build
