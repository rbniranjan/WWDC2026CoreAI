# Conversion Notes

## Intended Source Model

- Local YOLO checkpoint: `models/raw/best.pt`
- This file is expected locally and is intentionally excluded from Git.
- `best.pt` was validated locally in the project `.venv`.
- The model exposes `38` classes, and that class order matched `configs/full_plant_data.yaml` exactly.

## Phase 1B-2 Scope

- Environment validation is implemented.
- YAML label loading/validation is implemented.
- YOLO checkpoint inspection is implemented.
- Local detection JSON export is implemented.
- Intermediate export scripting for TorchScript/ONNX is implemented.
- Core AI conversion is implemented via `torch.export` plus `coreai_torch`.
- iOS handoff package generation is implemented.

## Output Locations

- Intermediate exports: `models/exported/`
- Core AI-ready outputs: `models/core-ai/`
- iOS handoff package: `models/ios-package/`

## Verified Export Results

- TorchScript export: success
  Path: `models/exported/best.torchscript`
- ONNX export: success
  Path: `models/exported/best.onnx`
- Export metadata: `models/exported/export_metadata.json`
- Core AI raw-output asset: success
  Path: `models/core-ai/FarmerHelper_YOLO26_RawDetector.aimodel`
- Core AI conversion metadata: `models/core-ai/core_ai_conversion_metadata.json`

The export script now normalizes generated artifacts into `models/exported/` so large local binaries do not linger unignored in `models/raw/`.

## Why The Core AI Asset Uses Raw Outputs

- The Core AI conversion wraps the detector and exports only `raw_boxes` and `raw_scores`.
- This avoids baking confidence filtering, class mapping, and NMS decisions into the asset conversion step.
- The Swift app owns postprocessing so thresholds, label presentation, and overlay logic remain explicit and debuggable on-device.

## Repeatable Conversion Runs

- `convert_to_core_ai.py` computes the target asset path before conversion starts.
- If `models/core-ai/FarmerHelper_YOLO26_RawDetector.aimodel` already exists, the script fails early by default and writes failure metadata.
- Use `--overwrite` to delete and replace only that exact asset path.
- The script never deletes the whole `models/core-ai/` directory.

## Exact Commands

```bash
cd Examples/01-CoreAI-PlantDiseaseDetector/python
python3 validate_environment.py
python3 inspect_yolo_model.py --model-path ../models/raw/best.pt --data-yaml configs/full_plant_data.yaml
python3 export_yolo_model.py --model-path ../models/raw/best.pt --output-dir ../models/exported --formats torchscript,onnx --imgsz 320
.venv-coreai/bin/python convert_to_core_ai.py --model-path ../models/raw/best.pt --output-dir ../models/core-ai --data-yaml configs/full_plant_data.yaml --imgsz 320 --overwrite
python3 create_ios_model_package.py --data-yaml configs/full_plant_data.yaml --output-dir ../models/ios-package --core-ai-dir ../models/core-ai
```

## Core AI Conversion Status

- Current status: successful local raw-output `.aimodel` generation.
- Verified local toolchain:
  - `torch 2.11.0`
  - `coreai_torch 0.4.0`
- Output names:
  - `raw_boxes`
  - `raw_scores`
- Output shapes from conversion metadata:
  - `[1, 4, 2100]`
  - `[1, 38, 2100]`
- Generated exports and conversion metadata remain local/ignored unless deliberately published later outside the Git repository.

## Exact TODOs Requiring Local Apple SDK Verification

1. Copy the resulting `.aimodel` into `ios/PlantDiseaseDetectorApp/PlantDiseaseDetectorApp/Resources/AIModels/` when you want to bundle it locally for app testing.
2. Implement Swift-side postprocessing for `raw_boxes` and `raw_scores`.
3. Replace the current mock-first runtime path with verified Core AI loading and inference behavior.
4. Verify the Xcode-side app integration path end to end.
