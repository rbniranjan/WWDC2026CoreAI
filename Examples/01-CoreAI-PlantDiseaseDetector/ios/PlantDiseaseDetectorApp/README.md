# PlantDiseaseDetectorApp

SwiftUI iOS app foundation for the Core AI plant disease object detector, including the Swift-side raw YOLO postprocessing path.

## App Purpose

- Select a photo from the user's library.
- Preview the image with detection overlays.
- Run detection through a Core AI placeholder boundary with mock fallback behavior.
- Display runtime mode, detections, confidence, and bounding box summaries.
- Keep model-specific postprocessing inside Swift instead of baking it into the Core AI asset.

## App Structure

```text
PlantDiseaseDetectorApp/
├── App/
├── Models/
├── ViewModels/
├── Views/
├── Services/
├── Components/
├── Resources/
└── Assets.xcassets/
```

## Run Instructions

1. Open `PlantDiseaseDetectorApp.xcodeproj`.
2. Set your signing team and update `PRODUCT_BUNDLE_IDENTIFIER` if required.
3. Run on a simulator or device with Photos access enabled.
4. Select an image and tap `Run Detection`.

## Raw Detector Contract

- Bundled labels: `PlantDiseaseDetectorApp/Resources/Labels/plant_disease_labels.json`
- Bundled model contract: `PlantDiseaseDetectorApp/Resources/ModelContract/model_contract.json`
- Expected Core AI entrypoint: `detect_raw`
- Expected input tensor: `image` `[1, 3, 320, 320]`
- Expected outputs:
  - `raw_boxes` `[1, 4, 2100]`
  - `raw_scores` `[1, 38, 2100]`

`DetectionPostProcessor.swift` is the app-side adapter for these outputs. It validates class count/order, selects the best class per anchor, converts `xyxy` model-space pixels into normalized `CGRect` values, then applies class-aware NMS using the bundled thresholds.

## Mock Detector Behavior

- The app attempts the Core AI detector path first in automatic mode.
- If no model asset is present, the mock detector returns deterministic sample detections.
- The runtime panel clearly reports `Mock fallback` when that path is active.
- That mock fallback remains the active local behavior unless the generated raw-output `.aimodel` is copied into the app bundle and the runtime loader is completed.

## Model Placement

Place future converted detector assets here:

```text
PlantDiseaseDetectorApp/Resources/AIModels/
```

Current locally generated asset:

```text
Examples/01-CoreAI-PlantDiseaseDetector/models/core-ai/FarmerHelper_YOLO26_RawDetector.aimodel
```

Labels are currently loaded from:

```text
PlantDiseaseDetectorApp/Resources/Labels/plant_disease_labels.json
```

The generated model contract is currently loaded from:

```text
PlantDiseaseDetectorApp/Resources/ModelContract/model_contract.json
```

## Known Limitations

- Real Core AI model loading and inference are still TODO pending SDK verification.
- The bundled label JSON now contains the verified real `38` class names from the validated YAML/model pair.
- The generated `.aimodel` stays local/ignored and is not committed or bundled automatically.
- Postprocessing for raw Core AI outputs is implemented in Swift, but it is not exercised end-to-end until the verified runtime loader is added.
- Xcode build success is not claimed unless separately verified in the local environment.

## Local Core Tests

- `Package.swift` exposes the pure-Swift detector core to SwiftPM.
- The local tests cover:
  - raw tensor shape validation
  - label order validation
  - raw output to normalized detection conversion
  - class-aware NMS behavior
- Run from this folder:
  `swift test --scratch-path /tmp/plant-disease-detector-swiftpm-build`
- This requires the local Xcode command line toolchain and accepted Apple SDK license terms.
