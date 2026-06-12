PREFIX ?= /usr/local

.PHONY: build install uninstall test

build:
	swift build -c release

test:
	swift test

install: build
	install -d $(PREFIX)/bin
	install .build/release/ghpr $(PREFIX)/bin/ghpr
	@echo "Installed $(PREFIX)/bin/ghpr"

uninstall:
	rm -f $(PREFIX)/bin/ghpr
