# iOS Demo Notes

This folder contains the `PlantDiseaseDetectorApp` SwiftUI app and the Swift-side raw YOLO postprocessing foundation for the plant disease detector example.

## Opening The Project

1. Open [PlantDiseaseDetectorApp.xcodeproj](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/01-CoreAI-PlantDiseaseDetector/ios/PlantDiseaseDetectorApp/PlantDiseaseDetectorApp.xcodeproj).
2. Set your Apple development team and preferred bundle identifier.
3. If you want local app-side model testing, copy the locally generated `.aimodel` into `PlantDiseaseDetectorApp/Resources/AIModels/`.
4. Build only after verifying the actual Core AI runtime APIs available in your installed Xcode / SDK setup.

## Runtime Strategy

- `CoreAIPlantDiseaseDetector.swift` keeps the Core AI boundary compile-safe and isolated.
- `DetectionPostProcessor.swift` is now the verified Swift-side adapter for raw detector tensors:
  - `raw_boxes` `[1, 4, 2100]`
  - `raw_scores` `[1, 38, 2100]`
- `MockPlantDiseaseDetector.swift` provides deterministic sample detections so the app can run before a real model is available.
- `DetectionOverlayView.swift` renders normalized bounding boxes over the selected image preview.
- The Swift postprocessor now owns best-class selection, confidence filtering, XYXY-to-`CGRect` normalization, and class-aware NMS.
- A real raw-output `.aimodel` now exists under `models/core-ai/`, but the app still uses the mock fallback path until that asset is bundled locally and the verified runtime code is completed.
- Real labels were copied into `Resources/Labels/plant_disease_labels.json`.
- The generated model contract was copied into `Resources/ModelContract/model_contract.json`.

## Local Swift Verification

- A small SwiftPM package was added in `PlantDiseaseDetectorApp/Package.swift`.
- It exposes the pure-Swift detector core and allows local unit tests without modifying the Xcode app target layout.
- The tests focus on raw tensor parsing, contract validation, and class-aware NMS behavior.
- Run from `ios/PlantDiseaseDetectorApp/`:
  `swift test --scratch-path /tmp/plant-disease-detector-swiftpm-build`
- This requires a local Xcode CLI toolchain with the Apple license already accepted.
