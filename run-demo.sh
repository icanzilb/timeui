#!/bin/zsh
set -e
echo "Running demo..."
swift build -c release
./.build/release/timeui ./.build/release/test-app
