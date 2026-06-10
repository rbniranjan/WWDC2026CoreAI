# iOS Integration Notes

## Folder Structure

```text
Examples/01-CoreAI-PlantDiseaseDetector/ios/
└── PlantDiseaseDetectorApp/
    ├── README.md
    ├── PlantDiseaseDetectorApp.xcodeproj/
    └── PlantDiseaseDetectorApp/
        ├── App/
        ├── Models/
        ├── ViewModels/
        ├── Views/
        ├── Services/
        ├── Components/
        ├── Resources/
        └── Assets.xcassets/
```

## Mock Mode

- The app prefers `CoreAIPlantDiseaseDetector` first when detection runs.
- If no real model asset is present, the app falls back to `MockPlantDiseaseDetector`.
- The mock detector returns deterministic sample detections and uses normalized bounding boxes so the overlay UI is demonstrable immediately.

## Model Placement

- Future converted Apple-side detector assets should be copied into:
  `Examples/01-CoreAI-PlantDiseaseDetector/ios/PlantDiseaseDetectorApp/PlantDiseaseDetectorApp/Resources/AIModels/`
- `CoreAIPlantDiseaseDetector.swift` only verifies model presence today. It does not contain unverified Core AI runtime calls.

## Labels

- Labels are loaded from:
  `Resources/Labels/plant_disease_labels.json`
- The current JSON is a clearly marked placeholder subset because the final exported class map has not been provided by the Python/model agent yet.

## What The Python / Model Agent Must Provide Later

- The converted detector model asset for iOS bundling.
- The verified class map / label file.
- Any post-processing rules needed for real detection output parsing.
- Confirmation of input preprocessing and output tensor contract after export.

## TODO Pending Xcode 27 / Core AI SDK Verification

- Replace the placeholder error path in `CoreAIPlantDiseaseDetector.swift` with the verified runtime loader and inference call.
- Confirm the final model bundle format expected by Core AI.
- Verify the Xcode project builds cleanly once the local Xcode license and SDK environment are available.

