# CoreAIChat

CoreAIChat is a SwiftUI app target for iPhone, iPad, and Mac Catalyst. It is the app implementation for `Examples/02-CoreAI-LocalChat`.

Phase 1 uses `MockChatRuntime` for a working chat experience. `CoreAIChatRuntime` is a compile-safe integration boundary that validates selected `.aimodel` files and reports that Core AI runtime integration is pending.

## Build

From this directory:

```bash
DEVELOPER_DIR=/Users/rniranjan/Downloads/Xcode-beta.app/Contents/Developer xcodebuild -project CoreAIChat.xcodeproj -scheme CoreAIChat -destination 'generic/platform=iOS Simulator' build
```

Run the package tests:

```bash
DEVELOPER_DIR=/Users/rniranjan/Downloads/Xcode-beta.app/Contents/Developer swift test
```

## Local Model Files

Manual model files go in:

```text
CoreAIChat/Resources/AIModels/
```

They must match the manifest file names in:

```text
CoreAIChat/Resources/ModelManifest/model_manifest.json
```
