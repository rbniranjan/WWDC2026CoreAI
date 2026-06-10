# PlantDiseaseDetectorApp

SwiftUI iOS app foundation for the Core AI plant disease object detector, including the Swift-side raw YOLO postprocessing path and local-only model sync workflow.

## What The App Does

- lets the user pick a photo
- renders detection overlays
- tries the Core AI detector path first
- falls back to deterministic mock detections if no local model is bundled
- displays runtime status, detection labels, confidence, and bounding box summaries

## Architecture

```text
FarmerHelper_YOLO26_RawDetector.aimodel
-> raw_boxes [1, 4, 2100]
-> raw_scores [1, 38, 2100]
-> DetectionPostProcessor.swift
-> PlantDiseaseDetection values
-> DetectionOverlayView.swift
```

## Raw Detector Contract

- input tensor: `image` `[1, 3, 320, 320]`
- layout: `NCHW`
- dtype: `float32`
- outputs:
  - `raw_boxes` `[1, 4, 2100]`
  - `raw_scores` `[1, 38, 2100]`
- classes: `38`
- confidence threshold: `0.35`
- IoU threshold: `0.45`

`DetectionPostProcessor.swift` handles:

- label count and order validation
- best-class selection per anchor
- confidence thresholding
- `xyxy` pixel to normalized `CGRect` conversion
- class-aware non-maximum suppression

## Why Raw Outputs Are Used

The conversion flow intentionally disables YOLO end-to-end postprocessing because direct end-to-end conversion hit an unsupported `aten.remainder.Scalar` path. That keeps postprocessing transparent and adjustable on the iOS side.

## Local Model Sync

Generated source model:

```text
Examples/01-CoreAI-PlantDiseaseDetector/models/core-ai/FarmerHelper_YOLO26_RawDetector.aimodel
```

App resource destination:

```text
PlantDiseaseDetectorApp/Resources/AIModels/FarmerHelper_YOLO26_RawDetector.aimodel
```

Sync helper:

```text
Examples/01-CoreAI-PlantDiseaseDetector/scripts/sync-local-aimodel.sh
```

That copied app-resource `.aimodel` remains ignored and local-only.

## Model Artifacts

The generated `.aimodel` is intentionally not committed. The same local-only policy applies to the trained `best.pt` model and generated conversion metadata.

If another developer needs the trained `best.pt` model or generated `.aimodel` for testing or review, they should open a GitHub issue, leave a comment on the repository, or contact the repository owner by email if a contact address is available.

## Run Instructions

1. Open `PlantDiseaseDetectorApp.xcodeproj`.
2. Set your signing team and update `PRODUCT_BUNDLE_IDENTIFIER` if required.
3. If you want to test the local model path, run `../scripts/sync-local-aimodel.sh`.
4. Run on a simulator or device with Photos access enabled.
5. Select an image and tap `Run Detection`.

## Xcode Beta Verification

Use inline `DEVELOPER_DIR`. Do not change the system default Xcode.

Verified local beta path on the author machine:

```bash
export BETA_DEVELOPER_DIR="/Users/rniranjan/Downloads/Xcode-beta.app/Contents/Developer"
```

Other developers should replace that path with their own Xcode beta path.

Commands:

```bash
DEVELOPER_DIR="$BETA_DEVELOPER_DIR" swift test --scratch-path /tmp/plant-disease-detector-swiftpm-build

DEVELOPER_DIR="$BETA_DEVELOPER_DIR" xcodebuild \
  -project PlantDiseaseDetectorApp.xcodeproj \
  -scheme PlantDiseaseDetectorApp \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/plant-disease-detector-derived-data \
  build
```

Verified result:

- SwiftPM tests: `4 tests, 0 failures`
- Xcode build: `BUILD SUCCEEDED`

## What Is Not Included Yet

- final production Core AI runtime API wiring beyond the current placeholder boundary
- committed model artifacts
- cloud download flow for model files
