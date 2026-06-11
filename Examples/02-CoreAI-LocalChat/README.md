# 02-CoreAI-LocalChat

CoreAIChat is a SwiftUI local-chat app foundation for Apple Core AI workflows. It provides the app shell around model discovery, settings, download state, and runtime boundaries without shipping real model artifacts.

## What The App Does

- Runs a polished SwiftUI chat interface with `MockChatRuntime`.
- Loads a JSON-driven model catalog from the app bundle.
- Optionally loads a remote manifest, caches it, and falls back safely.
- Detects manual local `.aimodel` files in `Resources/AIModels`.
- Persists active model selection and generation settings.
- Shows model availability, download state, and manifest source.
- Provides a download-manager foundation with Application Support storage and SHA-256 verification.
- Keeps `CoreAIChatRuntime` as a compile-safe boundary for future Core AI LLM integration.

## Current Scope

| Area | Status |
| --- | --- |
| Chat UI | Polished SwiftUI surface backed by mock generation |
| Model catalog | Bundled JSON plus optional remote, cached remote, and bundled fallback |
| Model list/detail | Card-based model browser with metadata, availability, and actions |
| Settings | Generation, model catalog, storage, and developer notes |
| Manual `.aimodel` setup | Supported for local testing |
| Downloads | Foundation implemented; archive extraction is future work |
| Real LLM generation | Not implemented |
| RAG/tokenizer/KV cache | Not implemented |

## Runtime Behavior

`MockChatRuntime` is the working runtime. The chat screen stays usable even when no model is installed.

`CoreAIChatRuntime` validates local model availability and reports that runtime integration is pending. It does not call invented Core AI APIs. When a selected model is missing, unavailable, or only present as a downloaded archive, the app falls back to the mock runtime.

Runtime integration research for Qwen-based Core AI bundles currently references [`john-rocky/coreai-model-zoo`](https://github.com/john-rocky/coreai-model-zoo) as an external Swift runtime candidate. See [docs/EXTERNAL_RUNTIME_INTEGRATION_PLAN.md](docs/EXTERNAL_RUNTIME_INTEGRATION_PLAN.md).

## Manual `.aimodel` Setup

Copy local test models into:

```text
Examples/02-CoreAI-LocalChat/CoreAIChat/CoreAIChat/Resources/AIModels/
```

The file name must exactly match the `fileName` value in:

```text
Examples/02-CoreAI-LocalChat/CoreAIChat/CoreAIChat/Resources/ModelManifest/model_manifest.json
```

`.aimodel` files are ignored by git and must not be committed.

## Build And Test

Use the Xcode beta inline. Do not change the default Xcode.

```bash
cd Examples/02-CoreAI-LocalChat/CoreAIChat

DEVELOPER_DIR="/Users/rniranjan/Downloads/Xcode-beta.app/Contents/Developer" swift test \
  --scratch-path /tmp/coreai-chat-swiftpm-build

DEVELOPER_DIR="/Users/rniranjan/Downloads/Xcode-beta.app/Contents/Developer" xcodebuild \
  -project CoreAIChat.xcodeproj \
  -scheme CoreAIChat \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/coreai-chat-derived-data \
  build
```

Expected local toolchain:

- Xcode 27.0
- Build version 27A5194q
- Swift 6.4

## What Is Intentionally Excluded

- Real `.aimodel` artifacts
- Model weights
- Python code
- `llama.cpp`
- Third-party inference runtimes
- Real Core AI LLM generation
- Tokenizer/KV-cache implementation
- RAG and document ingestion
- Archive extraction into installed `.aimodel` files

## Docs

- [Architecture](docs/ARCHITECTURE.md)
- [Model manifest](docs/MODEL_MANIFEST.md)
- [Manual model setup](docs/MANUAL_MODEL_SETUP.md)
- [Download manager](docs/DOWNLOAD_MANAGER.md)
- [Settings](docs/SETTINGS.md)
- [iPhone, iPad, and Mac support](docs/IOS_IPAD_MAC_SUPPORT.md)
- [Roadmap](docs/ROADMAP.md)
- [Verification](docs/VERIFICATION.md)
