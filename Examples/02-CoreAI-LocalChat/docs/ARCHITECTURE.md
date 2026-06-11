# Architecture

CoreAIChat is split into UI features, core services, storage, runtime boundaries, and shared utilities.

## Layers

- `Features/Chat`: chat messages, input, bubbles, and `ChatViewModel`.
- `Features/Models`: model list, model detail, download actions, and `ModelLibraryViewModel`.
- `Features/Settings`: generation, catalog, and storage settings.
- `Core/ModelCatalog`: bundled, remote, cached remote, and fallback manifest loading.
- `Core/Downloads`: download state, artifact metadata, checksum verification, and local artifact storage.
- `Core/Settings`: persisted generation and catalog preferences.
- `Core/Storage`: active model persistence and local model availability detection.
- `Core/Runtime`: `ChatModelRuntime`, `MockChatRuntime`, and `CoreAIChatRuntime`.
- `Shared`: small design and bundle-loading helpers.

SwiftUI views do not call Core AI APIs directly. Generation is routed through `ChatModelRuntime` so the mock runtime can be replaced by a real Core AI implementation later without reshaping the UI.

## Runtime Boundary

`MockChatRuntime` is the working runtime for the example.

`CoreAIChatRuntime` intentionally does not invent unreleased or uncertain LLM generation APIs. It validates local `.aimodel` presence and returns an integration-pending status.

The app only passes a model to the runtime when `LocalModelStore` reports a usable local `.aimodel`. Missing models, downloaded archives, and unavailable entries fall back to the mock runtime.

## Catalog And Downloads

`ModelCatalogService` loads the bundled manifest by default. When settings enable a remote manifest, it attempts the remote URL, writes a cached copy on success, falls back to the cached remote manifest on network or decode failure, then falls back to the bundled manifest.

`ModelDownloadManager` stores downloaded artifacts in Application Support under `CoreAIChat/DownloadedModels`. It verifies SHA-256 checksums when a manifest supplies `sha256`. Archive extraction is intentionally deferred, so a downloaded zip is visible as an artifact but is not runtime-ready until a future extraction pipeline produces a usable `.aimodel`.

## Settings

`AppSettingsStore` persists settings as JSON in `UserDefaults`. Generation values are validated before use, and catalog settings decide whether the app loads only the bundled manifest or attempts a remote manifest first.
