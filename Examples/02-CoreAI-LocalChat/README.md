# CoreAI Local Chat

CoreAI Local Chat is a Swift-only example for a local Apple Core AI chat app shell.

The app currently provides:

- SwiftUI chat window with a working mock runtime.
- Bundled JSON model manifest plus optional remote manifest loading.
- Cached remote-manifest fallback, then bundled-manifest fallback.
- Model list, model detail, active model selection, and availability states.
- Manual bundled `.aimodel` detection under the app resources folder.
- Download-manager foundation for manifest-backed model artifacts.
- Settings for generation defaults, manifest source, and storage visibility.
- A documented runtime boundary for future Core AI LLM generation integration.

This example intentionally does not include Python code, llama.cpp, third-party inference runtimes, RAG, or real model artifacts. Core AI generation remains behind `CoreAIChatRuntime` until the exact Apple runtime API surface is finalized.

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

Downloaded artifacts are stored under the app's Application Support container, not under the repository. Archive extraction is intentionally deferred; downloaded archives are recorded as local artifacts but are not treated as runtime-ready `.aimodel` files.
