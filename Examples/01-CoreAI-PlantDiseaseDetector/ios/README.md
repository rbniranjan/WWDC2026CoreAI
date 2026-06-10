# iOS Demo Notes

This folder now contains the `PlantDiseaseDetectorApp` SwiftUI app foundation for the plant disease object detector example.

## Opening The Project

1. Open [PlantDiseaseDetectorApp.xcodeproj](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/01-CoreAI-PlantDiseaseDetector/ios/PlantDiseaseDetectorApp/PlantDiseaseDetectorApp.xcodeproj).
2. Set your Apple development team and preferred bundle identifier.
3. If a converted model is available later, add it under `PlantDiseaseDetectorApp/Resources/AIModels/`.
4. Build only after verifying the actual Core AI runtime APIs available in your installed Xcode / SDK setup.

## Runtime Strategy

- `CoreAIPlantDiseaseDetector.swift` keeps the Core AI boundary compile-safe and isolated.
- `MockPlantDiseaseDetector.swift` provides deterministic sample detections so the app can run before a real model is available.
- `DetectionOverlayView.swift` renders normalized bounding boxes over the selected image preview.
- A real raw-output `.aimodel` now exists under `models/core-ai/`, but the app still uses the mock fallback path until that asset is bundled locally and the runtime code is completed.
- Real labels were copied into `Resources/Labels/plant_disease_labels.json`.
- The generated model contract was copied into `Resources/ModelContract/model_contract.json`.
