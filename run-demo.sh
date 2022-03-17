#!/bin/zsh
swift build -c release
./.build/release/timeui ./.build/release/test-app
