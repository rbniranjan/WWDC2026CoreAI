# Python YOLO Pipeline

This folder contains the Phase 1B-2 local export/conversion pipeline for the YOLO detector workflow.

## Purpose

- Validate the local Python environment before attempting YOLO inspection or export.
- Load and validate class labels from `configs/full_plant_data.yaml`.
- Inspect a local YOLO checkpoint at `../models/raw/best.pt`.
- Normalize detector outputs into a Python/iOS-friendly contract shape.
- Export intermediate detector artifacts into `../models/exported/`.
- Attempt Core AI conversion only when official tooling is actually discoverable.
- Generate an iOS handoff package in `../models/ios-package/`.

## Local Model Placement

Place the fine-tuned YOLO checkpoint here:

```text
Examples/01-CoreAI-PlantDiseaseDetector/models/raw/best.pt
```

This file is intentionally not committed to Git.

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
python3 convert_to_core_ai.py \
  --model-path ../models/raw/best.pt \
  --output-dir ../models/core-ai \
  --data-yaml configs/full_plant_data.yaml \
  --imgsz 320
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

- `configs/full_plant_data.yaml` is wired up for a 38-class dataset shape.
- Exact class names were not confirmed from existing repo contents in this phase.
- The YAML currently uses explicit placeholder labels and a TODO comment rather than invented disease names.

## Phase Boundary

- Full production-grade Ultralytics result parsing may still expand in later phases.
- Core AI conversion only proceeds when official tooling is actually present and verified.
- If official Core AI tooling is unavailable, `convert_to_core_ai.py` writes blocked metadata instead of faking success.
