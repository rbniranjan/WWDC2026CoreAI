# 02-CoreAI-LocalChat

Swift-only Core AI local chat app foundation with a model catalog, active model selection, manual local `.aimodel` support, and a compile-safe Core AI runtime boundary.

## Summary

This example is a local chat app shell for Apple Core AI workflows. It does not ship model files or real LLM generation yet, but it does include a working SwiftUI chat experience through `MockChatRuntime`, a JSON-driven model catalog, local model detection, model detail flows, active model selection, and a foundation for remote manifest and download workflows.

## Status

| Area | Status | Notes |
| --- | --- | --- |
| Chat UI | Working foundation | powered by `MockChatRuntime` |
| Model catalog | Implemented | bundled manifest plus remote/cached fallback |
| Active model selection | Implemented | persisted locally |
| Manual local `.aimodel` setup | Implemented | detects files under `Resources/AIModels` |
| `CoreAIChatRuntime` boundary | Implemented | compile-safe placeholder, no fake Core AI APIs |
| Settings screen | Implemented foundation | generation, catalog, storage visibility |
| Download manager | Implemented foundation | Application Support storage, checksum support, no archive extraction yet |
| SwiftPM tests | Passed | exact count not summarized here |
| Xcode beta build | Passed | verified with inline `DEVELOPER_DIR` |

## Architecture

```text
model_manifest.json
-> local model detection / remote catalog fallback
-> CoreAIChatRuntime or MockChatRuntime
-> chat UI, model detail, active model selection
```

## Current Scope

Phase 1:

- SwiftUI chat app shell
- mock runtime
- bundled model manifest
- model list and detail screens
- active model selection
- manual `.aimodel` detection

Phase 2 foundation:

- settings screen
- optional remote manifest loading with cached fallback
- download manager backed by Application Support storage
- availability states for bundled, downloaded, missing, and unsupported entries

## Manual `.aimodel` Setup

Place local models here:

```text
Examples/02-CoreAI-LocalChat/CoreAIChat/CoreAIChat/Resources/AIModels/
```

The file names must match entries in:

```text
Examples/02-CoreAI-LocalChat/CoreAIChat/CoreAIChat/Resources/ModelManifest/model_manifest.json
```

No real `.aimodel` files are committed to the repository.

## Runtime Boundary

`MockChatRuntime` is the working runtime for the example.

`CoreAIChatRuntime` exists as a compile-safe boundary that validates local `.aimodel` presence and reports that real Core AI runtime integration is still pending. It intentionally does not invent unreleased or uncertain Apple generation APIs.

## Model Artifact Policy

Local `.aimodel` files, downloaded model artifacts, build outputs, DerivedData, `.build`, and `.swiftpm` outputs are intentionally excluded from Git. If a reviewer needs model artifacts for testing, they should request them manually through a GitHub issue, repository comment, or direct owner contact.

## Verification

Use inline `DEVELOPER_DIR`. Do not change the system default Xcode.

Verified local beta path on the author machine:

```bash
export BETA_DEVELOPER_DIR="/Users/rniranjan/Downloads/Xcode-beta.app/Contents/Developer"
```

Commands:

```bash
cd Examples/02-CoreAI-LocalChat/CoreAIChat

DEVELOPER_DIR="$BETA_DEVELOPER_DIR" swift test --scratch-path /tmp/coreai-chat-swiftpm-build

DEVELOPER_DIR="$BETA_DEVELOPER_DIR" xcodebuild \
  -project CoreAIChat.xcodeproj \
  -scheme CoreAIChat \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/coreai-chat-derived-data \
  build
```

Verified results:

- SwiftPM tests: passed
- Xcode beta build: passed
- default Xcode: unchanged

## What Is Implemented

- SwiftUI chat shell
- JSON-driven model manifest
- local `.aimodel` detection
- active model selection
- mock runtime behavior
- compile-safe `CoreAIChatRuntime` boundary
- remote manifest and download-manager foundation
- settings foundation

## What Is Not Included Yet

- committed `.aimodel` files
- real Core AI LLM generation
- tokenizer / KV cache management
- archive extraction into runtime-ready downloaded `.aimodel` files
- RAG or local document pipelines

## Related Docs

- [Architecture](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/02-CoreAI-LocalChat/docs/ARCHITECTURE.md)
- [Model manifest](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/02-CoreAI-LocalChat/docs/MODEL_MANIFEST.md)
- [Manual model setup](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/02-CoreAI-LocalChat/docs/MANUAL_MODEL_SETUP.md)
- [Download manager](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/02-CoreAI-LocalChat/docs/DOWNLOAD_MANAGER.md)
- [Settings](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/02-CoreAI-LocalChat/docs/SETTINGS.md)
- [Roadmap](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/02-CoreAI-LocalChat/docs/ROADMAP.md)
- [Verification](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/02-CoreAI-LocalChat/docs/VERIFICATION.md)
