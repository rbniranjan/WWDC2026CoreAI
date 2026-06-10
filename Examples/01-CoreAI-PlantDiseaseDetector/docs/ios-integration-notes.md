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
- Today the app remains in this mock-fallback path unless you explicitly copy the generated `.aimodel` into the app bundle and wire up the runtime integration.

## Model Placement

- Future converted Apple-side detector assets should be copied into:
  `Examples/01-CoreAI-PlantDiseaseDetector/ios/PlantDiseaseDetectorApp/PlantDiseaseDetectorApp/Resources/AIModels/`
- `CoreAIPlantDiseaseDetector.swift` only verifies model presence today. It does not contain unverified Core AI runtime calls.
- A local Core AI raw-output model was generated at:
  `Examples/01-CoreAI-PlantDiseaseDetector/models/core-ai/FarmerHelper_YOLO26_RawDetector.aimodel`
- It is not auto-copied into the app bundle and is intentionally not committed.

## Labels

- Labels are loaded from:
  `Resources/Labels/plant_disease_labels.json`
- The current JSON was copied from the generated iOS handoff package and contains the verified `38` class names from the validated YAML/model pair.

## Model Contract

- The generated handoff contract was copied to:
  `Resources/ModelContract/model_contract.json`
- Current contract values:
  - input tensor: `image` `[1, 3, 320, 320]`
  - confidence threshold: `0.35`
  - IOU threshold: `0.45`
  - raw Core AI outputs:
    - `raw_boxes` `[1, 4, 2100]`
    - `raw_scores` `[1, 38, 2100]`

## Why Swift Owns Postprocessing

- The Core AI asset emits raw detector tensors, not final detections.
- This keeps thresholding, class selection, and any NMS policy transparent and adjustable inside the app.
- `DetectionPostProcessor.swift` now implements:
  - class-count and label-order validation
  - best-class selection per anchor
  - XYXY pixel to normalized `CGRect` conversion
  - class-aware non-maximum suppression
- The app still needs the verified Apple runtime loader/inference call; until then it remains on mock fallback.

## What Is Still Needed Later

- Optional local bundling of the generated `.aimodel` for app testing.
- Verified Core AI runtime loading/inference code once the SDK/API surface is confirmed.
- Any Core AI-specific output adaptation only if the verified runtime tensors differ from the current JSON contract.

## TODO Pending Xcode 27 / Core AI SDK Verification

- Replace the placeholder error path in `CoreAIPlantDiseaseDetector.swift` with the verified runtime loader and inference call that returns `raw_boxes` and `raw_scores`.
- Confirm the final model bundle/runtime invocation format expected by Core AI.
- Verify the Xcode project builds cleanly once the local Xcode license and SDK environment are available.
