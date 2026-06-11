# Settings

The settings screen is backed by `AppSettingsStore`, which saves JSON in `UserDefaults`.

## Generation

The app stores and validates:

- Context window
- Temperature
- Maximum output tokens
- Top P

`ChatViewModel` reads these values when sending a message. The current working runtime is still `MockChatRuntime`, and `CoreAIChatRuntime` remains an integration boundary.

## Model Catalog

By default, the app uses the bundled manifest. When remote manifests are enabled, the app attempts the configured URL first, caches a successful response, then falls back to the cached remote manifest or bundled manifest when needed.

The Models screen displays the active manifest source so local testing can confirm whether the app is using bundled, remote, cached remote, or fallback bundled data.

## Storage

Settings expose the app's current downloaded-artifact storage usage. Downloaded artifacts remain outside the repository and should not be committed.
