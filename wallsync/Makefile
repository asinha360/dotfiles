PREFIX ?= $(HOME)/.local
BIN := $(PREFIX)/bin

.PHONY: build test install

build:
	swift build -c release

test:
	swift test

install: build
	install -d $(BIN)
	install -m 755 .build/release/wallsync $(BIN)/wallsync
	codesign --force -s - --identifier com.user.wallsync $(BIN)/wallsync
