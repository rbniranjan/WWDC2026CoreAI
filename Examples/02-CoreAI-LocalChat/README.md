# CoreAI Local Chat

CoreAI Local Chat is a Swift-only Phase 1 example for a local Apple Core AI chat app shell.

The app currently provides:

- SwiftUI chat window with a working mock runtime.
- Bundled JSON model manifest.
- Model list, model detail, and active model selection.
- Local `.aimodel` detection under the app resources folder.
- A documented runtime boundary for future Core AI LLM generation integration.

This phase intentionally does not include a download manager, full settings screen, RAG, Python code, llama.cpp, third-party inference runtimes, or real model artifacts.

## Project

Open:

```text
Examples/02-CoreAI-LocalChat/CoreAIChat/CoreAIChat.xcodeproj
```

Use the Xcode beta inline for command-line builds:

```bash
DEVELOPER_DIR=/Users/rniranjan/Downloads/Xcode-beta.app/Contents/Developer xcodebuild -project CoreAIChat/CoreAIChat.xcodeproj -scheme CoreAIChat -destination 'generic/platform=iOS Simulator' build
```

Do not use `xcode-select -s`.

## Manual Models

Copy test `.aimodel` files into:

```text
CoreAIChat/CoreAIChat/Resources/AIModels/
```

The file names must match `CoreAIChat/CoreAIChat/Resources/ModelManifest/model_manifest.json`.

`.aimodel` files are ignored by git and must not be committed.
