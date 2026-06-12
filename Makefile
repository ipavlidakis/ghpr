VERSION ?= $(shell .build/release/ghpr --version 2>/dev/null || echo dev)
DIST = dist/ghpr-v$(VERSION)-arm64-macos.tar.gz

.PHONY: build test dist clean

build:
	swift build -c release

test:
	swift test

# The binary is not standalone: the tree-sitter grammar bundles (queries)
# and the demo fixture bundle must live next to the executable.
dist: build
	rm -rf dist/stage && mkdir -p dist/stage
	cp .build/release/ghpr dist/stage/
	cp -R .build/release/*.bundle dist/stage/
	tar -czf $(DIST) -C dist/stage .
	@shasum -a 256 $(DIST)

clean:
	rm -rf dist .build
