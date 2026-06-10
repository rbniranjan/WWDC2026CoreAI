# PlantDiseaseDetectorApp

SwiftUI iOS app foundation for the future Core AI plant disease object detector.

## App Purpose

- Select a photo from the user's library.
- Preview the image with detection overlays.
- Run detection through a Core AI placeholder boundary with mock fallback behavior.
- Display runtime mode, detections, confidence, and bounding box summaries.

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

## Mock Detector Behavior

- The app attempts the Core AI detector path first in automatic mode.
- If no model asset is present, the mock detector returns deterministic sample detections.
- The runtime panel clearly reports `Mock fallback` when that path is active.

## Model Placement

Place future converted detector assets here:

```text
PlantDiseaseDetectorApp/Resources/AIModels/
```

Labels are currently loaded from:

```text
PlantDiseaseDetectorApp/Resources/Labels/plant_disease_labels.json
```

## Known Limitations

- Real Core AI model loading and inference are still TODO pending SDK verification.
- The bundled label JSON is a placeholder subset until the Python/model agent exports the final class map.
- Xcode build success is not claimed unless separately verified in the local environment.
