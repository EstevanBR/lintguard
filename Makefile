.PHONY: build
build:
	swift build -c release --build-path bin
	@echo "Binary here: $$(pwd)/bin/release/lintguard"
