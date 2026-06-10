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
- Core AI conversion is implemented only as a real-tooling gate: it writes blocked metadata when official tooling is not discoverable and does not fake `.aimodel` output.
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

The export script now normalizes generated artifacts into `models/exported/` so large local binaries do not linger unignored in `models/raw/`.

## Exact Commands

```bash
cd Examples/01-CoreAI-PlantDiseaseDetector/python
python3 validate_environment.py
python3 inspect_yolo_model.py --model-path ../models/raw/best.pt --data-yaml configs/full_plant_data.yaml
python3 export_yolo_model.py --model-path ../models/raw/best.pt --output-dir ../models/exported --formats torchscript,onnx --imgsz 320
python3 convert_to_core_ai.py --model-path ../models/raw/best.pt --output-dir ../models/core-ai --data-yaml configs/full_plant_data.yaml --imgsz 320
python3 create_ios_model_package.py --data-yaml configs/full_plant_data.yaml --output-dir ../models/ios-package --core-ai-dir ../models/core-ai
```

## Core AI Conversion Status

- Current status: blocked after real local export.
- Exact Apple Core AI conversion APIs were not verified in this environment.
- Official Core AI Python tooling was not discoverable, so no `.aimodel` was generated.
- Exact blocked reason is recorded in `models/core-ai/core_ai_conversion_metadata.json`.
- Generated exports and conversion metadata remain local/ignored unless deliberately published later outside the Git repository.

## Exact TODOs Requiring Local Apple SDK Verification

1. Install or use Xcode 27 plus the official Core AI Python tooling when it becomes available locally.
2. Re-run `convert_to_core_ai.py` once the verified conversion API path is known.
3. Copy the resulting `.aimodel` into `ios/PlantDiseaseDetectorApp/PlantDiseaseDetectorApp/Resources/AIModels/`.
4. Replace the current mock-first runtime path with verified Core AI loading and inference behavior.
