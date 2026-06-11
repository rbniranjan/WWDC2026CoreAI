# Architecture

CoreAIChat is split into UI features, core services, storage, runtime boundaries, and shared utilities.

## Layers

- `Features/Chat`: chat messages, input, bubbles, and `ChatViewModel`.
- `Features/Models`: model list, model detail, and `ModelLibraryViewModel`.
- `Core/ModelCatalog`: manifest models and JSON loading.
- `Core/Storage`: active model persistence and local model file detection.
- `Core/Runtime`: `ChatModelRuntime`, `MockChatRuntime`, and `CoreAIChatRuntime`.
- `Shared`: small design and bundle-loading helpers.

SwiftUI views do not call Core AI APIs directly. Generation is routed through `ChatModelRuntime` so the mock runtime can be replaced by a real Core AI implementation later without reshaping the UI.

## Phase 1 Runtime

`MockChatRuntime` is the working runtime for Phase 1.

`CoreAIChatRuntime` intentionally does not invent unreleased or uncertain LLM generation APIs. It validates local `.aimodel` presence and returns an integration-pending status.
