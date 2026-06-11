# 01-CoreAI-PlantDiseaseDetector

YOLO-based plant disease detector example for Apple Core AI conversion, raw detector outputs, and Swift-side postprocessing.

## Summary

This example starts from a locally available YOLO checkpoint, converts it into a raw-output Core AI model, and feeds the detector outputs into a SwiftUI iOS app that performs class selection, confidence filtering, box conversion, and class-aware NMS on-device.

It is an object detection example, not a simple classifier.

## Status

| Area | Status | Notes |
| --- | --- | --- |
| YOLO class contract validation | Verified | `best.pt` matched YAML class order and count |
| Core AI conversion pipeline | Verified | Generates `FarmerHelper_YOLO26_RawDetector.aimodel` locally |
| Raw-output model contract | Implemented | `raw_boxes` and `raw_scores` contract documented and copied into the app |
| Swift postprocessing | Implemented | best class selection, confidence filtering, box conversion, class-aware NMS |
| Local `.aimodel` sync | Implemented | helper script copies local model into app resources |
| SwiftPM tests | Passed | 4 tests |
| Xcode beta build | Passed | verified with inline `DEVELOPER_DIR` |

## Architecture

```text
Examples/01-CoreAI-PlantDiseaseDetector/models/raw/best.pt
-> python/convert_to_core_ai.py
-> Examples/01-CoreAI-PlantDiseaseDetector/models/core-ai/FarmerHelper_YOLO26_RawDetector.aimodel
-> raw_boxes [1, 4, 2100]
-> raw_scores [1, 38, 2100]
-> ios/PlantDiseaseDetectorApp/PlantDiseaseDetectorApp/Services/Inference/DetectionPostProcessor.swift
-> final PlantDiseaseDetection values
-> SwiftUI detection overlay
```

## Why Raw Outputs Are Used

Direct YOLO postprocessed conversion hit an unsupported `aten.remainder.Scalar` path. The verified solution is to disable YOLO end-to-end postprocessing during conversion and export raw detector outputs instead.

That keeps Swift responsible for:

- best-class selection
- confidence thresholding
- `xyxy` box conversion to normalized `CGRect`
- class-aware NMS

## Core AI Model Contract

Input:

- `image` `[1, 3, 320, 320]`
- layout: `NCHW`
- dtype: `float32`

Outputs:

- `raw_boxes` `[1, 4, 2100]`
- `raw_scores` `[1, 38, 2100]`

Model / postprocessing defaults:

- class count: `38`
- confidence threshold: `0.35`
- IoU threshold: `0.45`
- postprocessing location: Swift / iOS

## Local Conversion Flow

Place the local trained model at:

```text
Examples/01-CoreAI-PlantDiseaseDetector/models/raw/best.pt
```

Run the conversion from `Examples/01-CoreAI-PlantDiseaseDetector/python`:

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

## iOS App Integration

Use the sync helper to copy the local model into the iOS app:

```text
Examples/01-CoreAI-PlantDiseaseDetector/scripts/sync-local-aimodel.sh
```

It copies:

- from:
  `Examples/01-CoreAI-PlantDiseaseDetector/models/core-ai/FarmerHelper_YOLO26_RawDetector.aimodel`
- to:
  `Examples/01-CoreAI-PlantDiseaseDetector/ios/PlantDiseaseDetectorApp/PlantDiseaseDetectorApp/Resources/AIModels/FarmerHelper_YOLO26_RawDetector.aimodel`

The copied app-resource `.aimodel` remains ignored and local-only.

## Verification Summary

- Python tests: passed
- Python compile check: passed
- Core AI conversion: passed
- SwiftPM tests: passed, 4 tests
- Xcode beta build: passed
- default Xcode: unchanged

## Model Artifacts

The trained YOLO `.pt` model, generated Core AI `.aimodel`, and generated conversion metadata are intentionally not committed. If you need the model artifacts for testing or review, please open a GitHub issue, leave a comment on the repository, or contact the repository owner. Artifacts can be shared manually when appropriate.

## What Is Implemented

- YOLO contract validation
- Core AI raw detector conversion
- raw-output model contract
- Swift postprocessing foundation
- class-aware NMS
- local-only model sync
- Xcode beta build verification

## What Is Not Included Yet

- model artifacts in Git
- cloud-hosted model downloads
- production Core AI runtime API final wiring beyond the current placeholder boundary
- training dataset or distributable model weights

## Related Docs

- [Python conversion notes](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/01-CoreAI-PlantDiseaseDetector/docs/conversion-notes.md)
- [iOS integration notes](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/01-CoreAI-PlantDiseaseDetector/docs/ios-integration-notes.md)
- [Model contract](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/01-CoreAI-PlantDiseaseDetector/docs/model-contract.md)
- [Verification report](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/01-CoreAI-PlantDiseaseDetector/docs/verification-report.md)
