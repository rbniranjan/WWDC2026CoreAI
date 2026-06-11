# Download Manager

The download manager is a Swift/Foundation/CryptoKit foundation for future model artifact delivery.

## Storage

Downloaded artifacts are written to the app's Application Support directory:

```text
Application Support/CoreAIChat/DownloadedModels/
```

The repository does not store downloaded artifacts. `.aimodel`, `DownloadedModels`, DerivedData, `.build`, and `.swiftpm` outputs are ignored.

## Behavior

- A model is downloadable only when the manifest sets `downloadSupported` and provides `downloadURL`.
- The manager downloads bytes with `URLSession` by default.
- Tests inject an in-memory data loader, so no network is needed.
- The manager verifies SHA-256 when `sha256` is present.
- Delete and retry are exposed through `ModelLibraryViewModel`.
- Cancellation is represented in the UI state and reserved for a future streaming download implementation.

## Runtime Readiness

Only local `.aimodel` files are runtime-ready. A downloaded `.aimodel` artifact can become usable when it is stored as a plain `.aimodel` file. Downloaded archives, including zip files, are recorded but not extracted in this phase.

Archive extraction, compatibility checks, and install-to-runtime flows are intentionally deferred.
