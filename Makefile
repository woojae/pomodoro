# Pomodoro menu bar app
#
#   make            Build a Release binary into ./build
#   make install    Build, quit the running app, copy to /Applications, relaunch
#   make run        Build Debug and launch it from ./build (no install)
#   make generate   Regenerate Pomodoro.xcodeproj from project.yml (needs xcodegen)
#   make clean      Remove build output

SHELL      := /bin/bash

APP        := Pomodoro
PROJECT    := $(APP).xcodeproj
BUILD_DIR  := build
INSTALL_TO := /Applications

XCODEBUILD := xcodebuild -project $(PROJECT) -scheme $(APP) -derivedDataPath $(BUILD_DIR)
RELEASE_APP := $(BUILD_DIR)/Build/Products/Release/$(APP).app
DEBUG_APP   := $(BUILD_DIR)/Build/Products/Debug/$(APP).app

.PHONY: all build debug install run quit generate clean

all: build

build:
	set -o pipefail; $(XCODEBUILD) -configuration Release build | grep -E "error:|warning: .*\.swift|BUILD"

debug:
	set -o pipefail; $(XCODEBUILD) -configuration Debug build | grep -E "error:|warning: .*\.swift|BUILD"

install: build quit
	rm -rf $(INSTALL_TO)/$(APP).app
	cp -R $(RELEASE_APP) $(INSTALL_TO)/
	open $(INSTALL_TO)/$(APP).app
	@echo "Installed and launched $(INSTALL_TO)/$(APP).app"

run: debug quit
	open $(DEBUG_APP)

quit:
	-osascript -e 'quit app "$(APP)"' 2>/dev/null
	@sleep 1

generate:
	xcodegen generate

clean:
	rm -rf $(BUILD_DIR)
