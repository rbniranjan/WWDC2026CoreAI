#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/CoreAIChat"
XCODE_DEVELOPER_DIR="/Users/rniranjan/Downloads/Xcode-beta.app/Contents/Developer"
CLANG_MODULE_CACHE_PATH_OVERRIDE="/tmp/coreai-chat-clang-module-cache"

echo "Using DEVELOPER_DIR=$XCODE_DEVELOPER_DIR"
DEVELOPER_DIR="$XCODE_DEVELOPER_DIR" xcodebuild -version
DEVELOPER_DIR="$XCODE_DEVELOPER_DIR" swift --version

cd "$APP_DIR"

mkdir -p "$CLANG_MODULE_CACHE_PATH_OVERRIDE"
DEVELOPER_DIR="$XCODE_DEVELOPER_DIR" CLANG_MODULE_CACHE_PATH="$CLANG_MODULE_CACHE_PATH_OVERRIDE" swift test --disable-sandbox --scratch-path /tmp/coreai-chat-swiftpm-build
DEVELOPER_DIR="$XCODE_DEVELOPER_DIR" xcodebuild \
  -project CoreAIChat.xcodeproj \
  -scheme CoreAIChat \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/coreai-chat-derived-data \
  build
