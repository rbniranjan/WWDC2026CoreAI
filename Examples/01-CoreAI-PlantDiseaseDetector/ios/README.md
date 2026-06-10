# iOS Demo Notes

This folder contains the `PlantDiseaseDetectorApp` SwiftUI app, the raw YOLO postprocessing foundation, and the local model sync workflow for the Core AI plant disease detector example.

## What Is Implemented

- compile-safe `CoreAIPlantDiseaseDetector.swift` boundary
- Swift raw detector postprocessing in `DetectionPostProcessor.swift`
- class-aware NMS in Swift
- local-only `.aimodel` sync workflow
- SwiftPM detector-core tests
- Xcode beta simulator build verification

## What Is Not Included Yet

- committed model artifacts
- final production Core AI runtime API wiring
- cloud model download flow

## Local Model Flow

Generated source model:

```text
Examples/01-CoreAI-PlantDiseaseDetector/models/core-ai/FarmerHelper_YOLO26_RawDetector.aimodel
```

App resource destination:

```text
Examples/01-CoreAI-PlantDiseaseDetector/ios/PlantDiseaseDetectorApp/PlantDiseaseDetectorApp/Resources/AIModels/FarmerHelper_YOLO26_RawDetector.aimodel
```

Sync helper:

```text
Examples/01-CoreAI-PlantDiseaseDetector/scripts/sync-local-aimodel.sh
```

The copied app-resource `.aimodel` remains ignored and local-only.

## Core AI Contract

- input: `image` `[1, 3, 320, 320]`
- layout: `NCHW`
- dtype: `float32`
- outputs:
  - `raw_boxes` `[1, 4, 2100]`
  - `raw_scores` `[1, 38, 2100]`
- classes: `38`
- confidence threshold: `0.35`
- IoU threshold: `0.45`

## Why Swift Owns Postprocessing

The Core AI asset emits raw detector outputs because direct end-to-end YOLO postprocessing conversion hit an unsupported `aten.remainder.Scalar` path. Swift therefore owns best-class selection, confidence filtering, `xyxy` box conversion, and class-aware NMS.

## Xcode Beta Verification

Do not change the system default Xcode. Use inline `DEVELOPER_DIR` only.

Verified local beta path on the author machine:

```bash
export BETA_DEVELOPER_DIR="/Users/rniranjan/Downloads/Xcode-beta.app/Contents/Developer"
```

Other developers should replace that path with their own Xcode beta install path.

Commands:

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

Verified results:

- `Xcode 27.0`
- `Build version 27A5194q`
- `Swift 6.4`
- SwiftPM tests: `4 tests, 0 failures`
- Xcode build: `BUILD SUCCEEDED`
- default Xcode was not changed

## Model Artifacts

The generated `.aimodel` is intentionally not committed. If another developer needs the local model artifacts for testing or review, they should request them manually through a GitHub issue, repository comment, or direct owner contact if an email address is available.
