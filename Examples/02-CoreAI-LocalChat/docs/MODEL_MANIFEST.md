# Model Manifest

The bundled model catalog is loaded from:

```text
CoreAIChat/CoreAIChat/Resources/ModelManifest/model_manifest.json
```

Each record includes:

- `id`
- `name`
- `family`
- `format`
- `quantization`
- `fileName`
- `contextWindow`
- `estimatedSize`
- `description`
- `expectedSizeBytes`
- `isBundled`
- `downloadSupported`
- `downloadURL`
- `artifactFileName`
- `artifactType`
- `sha256`
- `minimumOS`
- `supportedDevices`

The manifest is the source of truth for the model list and detail screens. Views should not hardcode model records, model names, model family labels, or download URLs.

Older manifest records that omit the Phase 2 download fields still decode with conservative defaults. By default, a record is treated as not bundled, not downloadable, and unavailable until a matching local artifact is present.

## Sources

The app supports four catalog source states:

- `bundled`: settings did not request a remote manifest.
- `remote`: a remote manifest was fetched, decoded, and cached.
- `cachedRemote`: remote loading failed, but a cached remote manifest decoded successfully.
- `fallbackBundled`: remote loading and cached remote loading were unavailable, so the bundled manifest was used.

Remote manifests must use the same schema as the bundled JSON. The app does not execute manifest content; URLs are only used by the download manager when a model is explicitly downloaded.

## UI Usage

The model list and model detail screens render directly from manifest data:

- model name, family, format, and quantization
- context window and expected size
- artifact type and checksum availability
- manual-only or downloadable state
- manifest source
- supported devices and minimum OS when present

## Artifacts

No real `.aimodel` files, model weights, or downloaded model artifacts are committed. Manual `.aimodel` files must live outside git, and downloaded artifacts are stored in the app's Application Support directory.
