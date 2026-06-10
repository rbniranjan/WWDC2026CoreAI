# WWDC2026CoreAI

Portfolio-style WWDC 2026 examples for Apple on-device AI workflows using Xcode 27, SwiftUI, and Apple Core AI.

## Current Example

- [Examples/01-CoreAI-PlantDiseaseDetector](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/01-CoreAI-PlantDiseaseDetector/README.md)
  End-to-end YOLO plant disease detector example covering model validation, Core AI conversion, Swift-side raw output postprocessing, and a SwiftUI inspection app.

## What This Repository Demonstrates

- Python-side YOLO contract validation against a real training YAML.
- Verified local Core AI conversion from `best.pt` to a raw-output `.aimodel`.
- A documented raw detector contract shared between Python and Swift.
- Swift-side postprocessing for `raw_boxes` and `raw_scores`.
- A SwiftUI iOS app foundation that can render detections with mock fallback or a locally copied model.
- Xcode beta verification using inline `DEVELOPER_DIR` without changing the system default Xcode.

## Architecture

```text
best.pt
-> convert_to_core_ai.py
-> FarmerHelper_YOLO26_RawDetector.aimodel
-> raw_boxes [1, 4, 2100]
-> raw_scores [1, 38, 2100]
-> DetectionPostProcessor.swift
-> final detections
-> SwiftUI overlay / app UI
```

## Model Artifacts

The trained YOLO `.pt` model and generated Core AI `.aimodel` are intentionally not committed to this repository because they are large generated artifacts. The same policy applies to generated conversion metadata and the copied app-resource `.aimodel` used for local iOS testing.

If you need the trained `best.pt` model or the generated `FarmerHelper_YOLO26_RawDetector.aimodel` for testing or review, please open a GitHub issue, leave a comment on the repository, or contact the repository owner by email if a contact address is available on the repository or GitHub profile. The artifacts can be shared manually when appropriate.

## What Is Implemented

- Core AI YOLO raw detector conversion.
- Raw detector model contract documentation.
- Swift-side class selection, confidence filtering, box normalization, and class-aware NMS.
- Local-only `.aimodel` sync workflow for the iOS app.
- SwiftPM tests for the pure detector core.
- Xcode beta simulator build verification for the demo app.

## What Is Not Included Yet

- Model artifacts in Git.
- Cloud-hosted model download flow.
- Training dataset contents or distributable model weights.
- Final production Core AI runtime API wiring beyond the current compile-safe placeholder boundary.

## Verification Notes

- Verified local Xcode beta result:
  - `Xcode 27.0`
  - `Build version 27A5194q`
  - `Swift 6.4`
- Verified SwiftPM tests:
  - `4 tests, 0 failures`
- Verified iOS app build result:
  - `BUILD SUCCEEDED`
- The system default Xcode was not changed for verification.
