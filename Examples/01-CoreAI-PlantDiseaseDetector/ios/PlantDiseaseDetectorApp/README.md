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
- That mock fallback remains the active local behavior unless the generated raw-output `.aimodel` is copied into the app bundle and the runtime loader/postprocessing path is completed.

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
- Postprocessing for raw Core AI outputs still needs to be implemented in Swift.
- Xcode build success is not claimed unless separately verified in the local environment.
