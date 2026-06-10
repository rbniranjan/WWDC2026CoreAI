# iOS Integration Notes

## Overview

The iOS side of this example is a SwiftUI inspection app plus a pure-Swift raw detector postprocessing layer. The Core AI runtime boundary remains compile-safe and intentionally avoids unverified Apple APIs.

Architecture:

```text
FarmerHelper_YOLO26_RawDetector.aimodel
-> raw_boxes [1, 4, 2100]
-> raw_scores [1, 38, 2100]
-> DetectionPostProcessor.swift
-> PlantDiseaseDetection values
-> DetectionOverlayView.swift / result UI
```

## What Is Implemented

- `PlantDiseaseDetectorApp` SwiftUI app scaffold
- image selection flow
- runtime status panel
- mock fallback detector
- raw detector contract documentation
- `DetectionPostProcessor.swift` raw tensor parsing
- class-aware NMS in Swift
- local-only `.aimodel` sync workflow
- Xcode beta build verification

## What Is Not Included Yet

- Production Core AI runtime loading/inference API wiring beyond the current placeholder boundary
- Committed model artifacts
- Cloud-hosted model download flow

## Mock And Real Model Modes

- The app prefers `CoreAIPlantDiseaseDetector` first.
- If no local `.aimodel` is bundled, it falls back to `MockPlantDiseaseDetector`.
- The mock detector returns deterministic sample detections so the overlay UI remains demonstrable.
- The real runtime path is still intentionally behind a compile-safe placeholder until Apple Core AI runtime APIs are finalized and verified locally.

## Model Placement

Local app-resource model path:

```text
Examples/01-CoreAI-PlantDiseaseDetector/ios/PlantDiseaseDetectorApp/PlantDiseaseDetectorApp/Resources/AIModels/FarmerHelper_YOLO26_RawDetector.aimodel
```

Local generated source model path:

```text
Examples/01-CoreAI-PlantDiseaseDetector/models/core-ai/FarmerHelper_YOLO26_RawDetector.aimodel
```

Use the sync helper:

```text
Examples/01-CoreAI-PlantDiseaseDetector/scripts/sync-local-aimodel.sh
```

That copied app-resource `.aimodel` remains ignored and local-only.

## Raw Detector Contract

Input:

- `image` `[1, 3, 320, 320]`
- `NCHW`
- `float32`

Outputs:

- `raw_boxes` `[1, 4, 2100]`
- `raw_scores` `[1, 38, 2100]`

Class / threshold defaults:

- classes: `38`
- confidence threshold: `0.35`
- IoU threshold: `0.45`

## Why Swift Owns Postprocessing

The Core AI asset does not emit final postprocessed detections. That is intentional.

Direct end-to-end YOLO postprocessing conversion hit an unsupported `aten.remainder.Scalar` path, so the conversion flow disables YOLO end-to-end export behavior and keeps postprocessing in Swift.

`DetectionPostProcessor.swift` now owns:

- label count and order validation
- best-class selection per anchor
- confidence thresholding
- `xyxy` pixel to normalized `CGRect` conversion
- class-aware non-maximum suppression

## Xcode Beta Verification

The iOS app was verified with Xcode beta using inline `DEVELOPER_DIR`. The system default Xcode was not changed.

Verified local beta path on the author machine:

```bash
export BETA_DEVELOPER_DIR="/Users/rniranjan/Downloads/Xcode-beta.app/Contents/Developer"
```

Other developers should replace that path with their own Xcode beta install path.

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

Latest verified result:

- `Xcode 27.0`
- `Build version 27A5194q`
- `Swift 6.4`
- SwiftPM tests: `4 tests, 0 failures`
- Xcode build: `BUILD SUCCEEDED`

## Model Artifacts

The generated `.aimodel` is intentionally not committed. If another developer needs the local source `.aimodel` or `best.pt` for testing or review, they should request it manually through a GitHub issue, repository comment, or direct owner contact if an email address is available.
