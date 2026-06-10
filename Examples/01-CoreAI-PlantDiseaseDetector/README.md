# Core AI Plant Disease Detector

`Examples/01-CoreAI-PlantDiseaseDetector` is a YOLO-based plant disease object detector example for a WWDC 2026 / Apple Core AI portfolio repository. It is not a simple classifier example. The example covers model validation, Core AI conversion, Swift-side raw output postprocessing, and a SwiftUI iOS app foundation.

## What This Example Does

- Validates a local YOLO detector checkpoint against `python/configs/full_plant_data.yaml`.
- Converts the local checkpoint into a raw-output Core AI asset.
- Preserves a strict model contract between Python and iOS.
- Uses Swift to interpret raw detector outputs and render final detections.
- Provides an iOS demo app with a mock fallback path when no local model is bundled.

## Architecture

```text
Examples/01-CoreAI-PlantDiseaseDetector/models/raw/best.pt
-> python/convert_to_core_ai.py
-> Examples/01-CoreAI-PlantDiseaseDetector/models/core-ai/FarmerHelper_YOLO26_RawDetector.aimodel
-> raw_boxes [1, 4, 2100]
-> raw_scores [1, 38, 2100]
-> ios/PlantDiseaseDetectorApp/PlantDiseaseDetectorApp/Services/Inference/DetectionPostProcessor.swift
-> PlantDiseaseDetection values
-> SwiftUI overlay and result UI
```

## Why The Core AI Model Uses Raw Outputs

Direct YOLO end-to-end postprocessing conversion hit an unsupported `aten.remainder.Scalar` path. The verified solution is to disable YOLO end-to-end postprocessing before export so the Core AI asset emits raw detector tensors instead of final postprocessed detections.

That keeps the Swift app responsible for:

- class winner selection
- confidence thresholding
- `xyxy` box conversion into normalized `CGRect`
- class-aware non-maximum suppression

## Core AI Model Contract

Input:

- `image`
- shape: `[1, 3, 320, 320]`
- layout: `NCHW`
- dtype: `float32`

Outputs:

- `raw_boxes`
  - shape: `[1, 4, 2100]`
  - semantic: `xyxy` pixel coordinates in `320x320` model space
- `raw_scores`
  - shape: `[1, 38, 2100]`
  - semantic: per-class detector scores for each anchor

Postprocessing defaults:

- class count: `38`
- confidence threshold: `0.35`
- IoU threshold: `0.45`
- NMS: class-aware, implemented in Swift

## What Is Implemented

- YOLO class contract validation.
- Core AI raw detector conversion.
- Raw-output model contract documentation.
- Swift postprocessing foundation.
- Class-aware NMS in `DetectionPostProcessor.swift`.
- SwiftUI detection overlay and app UI scaffold.
- Local-only model sync script for the iOS app.
- SwiftPM detector-core tests.
- Xcode beta build verification.

## What Is Not Included Yet

- `best.pt` in Git.
- `FarmerHelper_YOLO26_RawDetector.aimodel` in Git.
- Generated conversion metadata in Git.
- Cloud-hosted model downloads.
- Training dataset or distributable model weights.
- Final production Core AI runtime API wiring beyond the current compile-safe placeholder boundary.

## Model Artifacts

The trained YOLO `.pt` model and generated Core AI `.aimodel` are intentionally not committed to this repository because they are large generated artifacts. Generated conversion metadata is also intentionally kept local-only.

If you need the trained `best.pt` model or the generated `FarmerHelper_YOLO26_RawDetector.aimodel` for testing or review, please open a GitHub issue, leave a comment on the repository, or contact the repository owner by email if a contact address is available on the repository or GitHub profile. The artifacts can be shared manually when appropriate.

## Reproducing The Local Model Flow

Place the local trained model here:

```text
Examples/01-CoreAI-PlantDiseaseDetector/models/raw/best.pt
```

Run the Core AI conversion from:

```bash
cd Examples/01-CoreAI-PlantDiseaseDetector/python
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

## Python Verification

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

## iOS Local Model Sync

Use the existing helper script:

```text
Examples/01-CoreAI-PlantDiseaseDetector/scripts/sync-local-aimodel.sh
```

It copies the model:

- from:
  `Examples/01-CoreAI-PlantDiseaseDetector/models/core-ai/FarmerHelper_YOLO26_RawDetector.aimodel`
- to:
  `Examples/01-CoreAI-PlantDiseaseDetector/ios/PlantDiseaseDetectorApp/PlantDiseaseDetectorApp/Resources/AIModels/FarmerHelper_YOLO26_RawDetector.aimodel`

The copied app-resource `.aimodel` is still ignored and local-only.

## iOS Verification With Xcode Beta

Do not change the system default Xcode. Use inline `DEVELOPER_DIR` only.

Verified local beta path on the author machine:

```bash
export BETA_DEVELOPER_DIR="/Users/rniranjan/Downloads/Xcode-beta.app/Contents/Developer"
```

Other developers should replace that path with their own Xcode beta installation path.

Verification commands:

```bash
DEVELOPER_DIR="$BETA_DEVELOPER_DIR" xcodebuild -version
DEVELOPER_DIR="$BETA_DEVELOPER_DIR" xcrun swift --version

cd Examples/01-CoreAI-PlantDiseaseDetector/ios/PlantDiseaseDetectorApp

DEVELOPER_DIR="$BETA_DEVELOPER_DIR" swift test --scratch-path /tmp/plant-disease-detector-swiftpm-build

DEVELOPER_DIR="$BETA_DEVELOPER_DIR" xcodebuild \
  -project PlantDiseaseDetectorApp.xcodeproj \
  -scheme PlantDiseaseDetectorApp \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/plant-disease-detector-derived-data \
  build
```

Latest verified local result:

- `Xcode 27.0`
- `Build version 27A5194q`
- `Swift 6.4`
- SwiftPM tests: `4 tests, 0 failures`
- Xcode build: `BUILD SUCCEEDED`
- Default Xcode was not changed

## Where To Read More

- Python conversion details: [docs/conversion-notes.md](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/01-CoreAI-PlantDiseaseDetector/docs/conversion-notes.md)
- iOS integration details: [docs/ios-integration-notes.md](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/01-CoreAI-PlantDiseaseDetector/docs/ios-integration-notes.md)
- Raw model contract: [docs/model-contract.md](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/01-CoreAI-PlantDiseaseDetector/docs/model-contract.md)
- Verification history: [docs/verification-report.md](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/01-CoreAI-PlantDiseaseDetector/docs/verification-report.md)
