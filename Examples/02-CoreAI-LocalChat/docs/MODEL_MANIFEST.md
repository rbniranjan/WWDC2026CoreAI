# Model Manifest

The model catalog is loaded from:

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

The manifest is the source of truth for the model list and detail screens. Views should not hardcode model records.

Phase 1 includes placeholder records only. No real `.aimodel` files or model weights are committed.
