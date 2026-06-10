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
- Today the app remains in this mock-fallback path because no real `.aimodel` was generated locally.

## Model Placement

- Future converted Apple-side detector assets should be copied into:
  `Examples/01-CoreAI-PlantDiseaseDetector/ios/PlantDiseaseDetectorApp/PlantDiseaseDetectorApp/Resources/AIModels/`
- `CoreAIPlantDiseaseDetector.swift` only verifies model presence today. It does not contain unverified Core AI runtime calls.
- The latest local Core AI conversion attempt was blocked because official Core AI Python tooling was not discoverable, so `Resources/AIModels/` still contains README-only guidance.

## Labels

- Labels are loaded from:
  `Resources/Labels/plant_disease_labels.json`
- The current JSON was copied from the generated iOS handoff package and contains the verified `38` class names from the validated YAML/model pair.

## Model Contract

- The generated handoff contract was copied to:
  `Resources/ModelContract/model_contract.json`
- Current contract values:
  - input image size: `320`
  - confidence threshold: `0.35`
  - IOU threshold: `0.45`

## What Is Still Needed Later

- The converted `.aimodel` for iOS bundling.
- Verified Core AI runtime loading/inference code once the SDK/API surface is confirmed.
- Any Core AI-specific post-processing adjustments if the exported runtime output differs from the current JSON contract.

## TODO Pending Xcode 27 / Core AI SDK Verification

- Replace the placeholder error path in `CoreAIPlantDiseaseDetector.swift` with the verified runtime loader and inference call.
- Confirm the final model bundle format expected by Core AI.
- Verify the Xcode project builds cleanly once the local Xcode license and SDK environment are available.
