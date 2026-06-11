#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/CoreAIChat"
export DEVELOPER_DIR="/Users/rniranjan/Downloads/Xcode-beta.app/Contents/Developer"

echo "Using DEVELOPER_DIR=$DEVELOPER_DIR"
xcodebuild -version
swift --version

cd "$APP_DIR"

swift test
xcodebuild \
  -project CoreAIChat.xcodeproj \
  -scheme CoreAIChat \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/CoreAIChatDerivedData \
  build
