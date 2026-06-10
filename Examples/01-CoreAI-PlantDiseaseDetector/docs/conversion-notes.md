# Conversion Notes

## Intended Source Model

- Local YOLO checkpoint: `models/raw/best.pt`
- This file is expected locally and is intentionally excluded from Git.

## Phase 1B-2 Scope

- Environment validation is implemented.
- YAML label loading/validation is implemented.
- YOLO checkpoint inspection is implemented.
- Local detection JSON export is implemented.
- Intermediate export scripting for TorchScript/ONNX is implemented.
- Core AI conversion is implemented only as a real-tooling gate: it writes blocked metadata when official tooling is not discoverable and does not fake `.aimodel` output.
- iOS handoff package generation is implemented.

## Planned Output Locations

- Intermediate exports: `models/exported/`
- Core AI-ready outputs: `models/core-ai/`
- iOS handoff package: `models/ios-package/`

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

- Current status: export/conversion scripts are in place, but actual runtime success depends on local model availability and Python dependencies.
- Exact Apple Core AI conversion APIs were not verified in this environment.
- No claim is made that a final `.aimodel` was produced unless it actually exists in `models/core-ai/`.

## Exact TODOs Requiring Local Apple SDK Verification

1. Verify the official Apple Core AI conversion/runtime APIs in the installed Xcode/SDK.
2. Confirm the final label list against the real 38-class training data and `best.pt`.
3. Replace the TODO runtime placeholder in `ios/PlantLeafClassifierApp/PlantLeafClassifierApp/CoreAIPlantDiseaseDetector.swift`.
4. Confirm the expected model bundle format and output post-processing requirements for detections.
