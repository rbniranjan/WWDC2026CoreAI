# Python YOLO Pipeline

This folder contains the Phase 1B-2 local export/conversion pipeline for the YOLO detector workflow.

## Purpose

- Validate the local Python environment before attempting YOLO inspection or export.
- Load and validate class labels from `configs/full_plant_data.yaml`.
- Inspect a local YOLO checkpoint at `../models/raw/best.pt`.
- Normalize detector outputs into a Python/iOS-friendly contract shape.
- Export intermediate detector artifacts into `../models/exported/`.
- Convert the model to a Core AI raw-output asset when `.venv-coreai` and `coreai_torch` are available.
- Generate an iOS handoff package in `../models/ios-package/`.

## Local Model Placement

Place the fine-tuned YOLO checkpoint here:

```text
Examples/01-CoreAI-PlantDiseaseDetector/models/raw/best.pt
```

This file is intentionally not committed to Git.

## Verified Local Status

- `best.pt` was validated locally from `../models/raw/best.pt`.
- The model and YAML each reported `38` classes.
- The model class order matched `configs/full_plant_data.yaml` exactly.
- TorchScript export succeeded to `../models/exported/best.torchscript`.
- ONNX export succeeded to `../models/exported/best.onnx`.
- Core AI raw-output conversion succeeded to `../models/core-ai/FarmerHelper_YOLO26_RawDetector.aimodel`.
- The generated iOS handoff package includes `model_contract.json` and the real `38`-class `plant_disease_labels.json`.

## Why Core AI Uses Raw Detector Outputs

- The Core AI asset exports `raw_boxes` and `raw_scores` directly from the YOLO detect head.
- This keeps the asset focused on stable tensor inference rather than baking postprocessing assumptions into the conversion.
- The iOS app is responsible for confidence filtering, any NMS/postprocessing policy, class mapping, and overlay rendering in Swift.

## Install Dependencies

```bash
cd Examples/01-CoreAI-PlantDiseaseDetector/python
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Run Environment Validation

```bash
python3 validate_environment.py
```

## Inspect The YOLO Model

```bash
python3 inspect_yolo_model.py
```

Optional flags:

```bash
python3 inspect_yolo_model.py \
  --model-path ../models/raw/best.pt \
  --data-yaml configs/full_plant_data.yaml
```

## Run One Local Detection

```bash
python3 run_local_detection.py \
  --model-path ../models/raw/best.pt \
  --image-path /absolute/path/to/sample.jpg \
  --data-yaml configs/full_plant_data.yaml \
  --output-json outputs/sample_detection.json \
  --conf 0.35 \
  --iou 0.45
```

Current verification note:

- No reasonable plant/leaf sample image was present in the repository, so local one-image detection was not run during this handoff pass.

## Export Intermediate Artifacts

```bash
python3 export_yolo_model.py \
  --model-path ../models/raw/best.pt \
  --output-dir ../models/exported \
  --formats torchscript,onnx \
  --imgsz 320
```

## Attempt Core AI Conversion

```bash
.venv-coreai/bin/python convert_to_core_ai.py \
  --model-path ../models/raw/best.pt \
  --output-dir ../models/core-ai \
  --data-yaml configs/full_plant_data.yaml \
  --imgsz 320
```

Expected local outputs:

- `../models/core-ai/FarmerHelper_YOLO26_RawDetector.aimodel`
- `../models/core-ai/core_ai_conversion_metadata.json`

Repeatable reruns:

- If the `.aimodel` already exists, the script fails early by default.
- Re-run with `--overwrite` to replace only that exact asset path.
- The script never deletes the whole `models/core-ai/` directory.

```bash
.venv-coreai/bin/python convert_to_core_ai.py \
  --model-path ../models/raw/best.pt \
  --output-dir ../models/core-ai \
  --data-yaml configs/full_plant_data.yaml \
  --imgsz 320 \
  --overwrite
```

## Create The iOS Handoff Package

```bash
python3 create_ios_model_package.py \
  --data-yaml configs/full_plant_data.yaml \
  --output-dir ../models/ios-package \
  --core-ai-dir ../models/core-ai
```

## Run Tests

```bash
python3 -m pytest tests
```

## Current Label Status

- `configs/full_plant_data.yaml` contains the real `38` validated class names.
- No placeholder label markers remain in the active YAML or generated handoff package.

## Phase Boundary

- Full production-grade Ultralytics result parsing may still expand in later phases.
- Core AI conversion uses the verified local `coreai_torch` path in `.venv-coreai`.
- The Core AI asset intentionally exposes raw detector outputs, so Swift remains responsible for postprocessing.
- Generated export/conversion binaries remain local and ignored by Git unless intentionally distributed later outside the repository.
