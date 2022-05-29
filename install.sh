#!/bin/zsh
echo "Building..."
set -e
swift build -c release
cp ./.build/release/timeui /usr/local/bin/timeui
echo "Installed: /usr/local/bin/timeui"
