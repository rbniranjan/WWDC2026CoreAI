# Conversion Notes

## Overview

The Python conversion flow takes a locally available YOLO checkpoint and produces a local-only Apple Core AI raw detector asset for the iOS app.

Architecture:

```text
best.pt
-> convert_to_core_ai.py
-> FarmerHelper_YOLO26_RawDetector.aimodel
-> raw_boxes [1, 4, 2100]
-> raw_scores [1, 38, 2100]
-> DetectionPostProcessor.swift
-> final detections
-> iOS UI overlay
```

## Intended Source Model

- Local YOLO checkpoint: `models/raw/best.pt`
- This file is intentionally excluded from Git.
- The model exposes `38` classes.
- The model class order matched `configs/full_plant_data.yaml` exactly during verification.

## Why Raw Outputs Are Used

Direct postprocessed YOLO conversion ran into an unsupported `aten.remainder.Scalar` path. The verified workaround is to disable YOLO end-to-end postprocessing before export and convert only the raw detector outputs.

That means the Core AI asset emits:

- `raw_boxes`
- `raw_scores`

And Swift owns:

- class winner selection
- confidence thresholding
- `xyxy` pixel to normalized `CGRect` conversion
- class-aware NMS

## Verified Output Contract

Input:

- `image`
- shape: `[1, 3, 320, 320]`
- layout: `NCHW`
- dtype: `float32`

Outputs:

- `raw_boxes`: `[1, 4, 2100]`
- `raw_scores`: `[1, 38, 2100]`

Class / threshold defaults:

- class count: `38`
- confidence threshold: `0.35`
- IoU threshold: `0.45`
- runtime entrypoint: `detect_raw`

## Output Locations

- Intermediate exports: `models/exported/`
- Core AI-ready outputs: `models/core-ai/`
- iOS handoff package: `models/ios-package/`

## Reproducing The Local Conversion

From `Examples/01-CoreAI-PlantDiseaseDetector/python`:

```bash
.venv/bin/python -m pytest tests
.venv/bin/python -m py_compile *.py

MPLCONFIGDIR=/tmp/mpl .venv-coreai/bin/python convert_to_core_ai.py \
  --model-path ../models/raw/best.pt \
  --output-dir ../models/core-ai \
  --data-yaml configs/full_plant_data.yaml \
  --imgsz 320 \
  --overwrite
```

Expected local outputs:

```text
Examples/01-CoreAI-PlantDiseaseDetector/models/core-ai/FarmerHelper_YOLO26_RawDetector.aimodel
Examples/01-CoreAI-PlantDiseaseDetector/models/core-ai/core_ai_conversion_metadata.json
```

## Repeatable Conversion Runs

- `convert_to_core_ai.py` computes the target asset path before conversion starts.
- If `FarmerHelper_YOLO26_RawDetector.aimodel` already exists, the script fails early by default.
- Use `--overwrite` to replace only that exact asset path.
- The script never deletes the whole `models/core-ai/` directory.

## Model Artifacts

The trained YOLO `.pt` model, generated Core AI `.aimodel`, and generated conversion metadata are intentionally not committed to Git. These files are large generated artifacts and remain local-only.

If another developer needs `best.pt` or `FarmerHelper_YOLO26_RawDetector.aimodel` for testing or review, they should open a GitHub issue, leave a comment on the repository, or contact the repository owner by email if a contact address is provided on the repository or GitHub profile.

## Current Verified Status

- YOLO checkpoint inspection: implemented and verified
- YAML label validation: implemented and verified
- TorchScript / ONNX export: implemented and verified
- Core AI raw detector conversion: implemented and verified
- iOS handoff package generation: implemented and verified

## Not Included

- Model artifacts in Git
- Cloud download flow for `best.pt` or `.aimodel`
- Final production Core AI runtime wiring inside the app
