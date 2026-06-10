# Models

Place the local YOLO checkpoint here:

```text
models/raw/best.pt
```

This file is intentionally not committed to Git.

Expected generated outputs:

```text
models/exported/
models/core-ai/
models/ios-package/
```

Pipeline notes:

- The Python pipeline now validates the expected raw model location before any inspection/export work.
- `best.pt` is optional during environment validation, but model inspection/export require it.
- `models/exported/` stores TorchScript/ONNX export artifacts and `export_metadata.json`.
- `models/core-ai/` stores Core AI conversion metadata and, if conversion ever succeeds, the final `.aimodel`.
- `models/ios-package/` stores the iOS handoff package with `model_contract.json`, `plant_disease_labels.json`, and `README.md`.
