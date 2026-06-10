# Core AI Plant Disease Detector

This example is a YOLO-based plant disease object detector with a verified local Core AI conversion path and an iOS app foundation that is ready to postprocess raw detector outputs in Swift.

## Current Status

- The local YOLO checkpoint at `models/raw/best.pt` was validated against `python/configs/full_plant_data.yaml`.
- The Python pipeline can export TorchScript, ONNX, and a local raw-output Core AI asset.
- The Swift app owns postprocessing for `raw_boxes` and `raw_scores`.
- Exact Apple runtime loading/inference APIs are still intentionally left behind a compile-safe placeholder until they are verified in the local Xcode/Core AI SDK environment.

## What This Example Is For

- Keep the YOLO training/export assets local and ignored.
- Preserve a clear contract between Python conversion and Swift runtime code.
- Demonstrate how a Core AI detector can emit raw tensors while iOS retains explicit control over thresholding and NMS.
- Provide a small SwiftUI inspection app with a deterministic mock fallback while the Apple runtime path is being verified.

## Folder Structure

```text
Examples/01-CoreAI-PlantDiseaseDetector/
├── README.md
├── models/
│   ├── README.md
│   ├── raw/
│   │   └── .gitkeep
│   ├── exported/
│   │   └── .gitkeep
│   └── core-ai/
│       └── .gitkeep
├── python/
│   ├── README.md
│   ├── convert_to_core_ai.py
│   ├── create_ios_model_package.py
│   ├── inspect_yolo_model.py
│   ├── export_yolo_model.py
│   ├── validate_environment.py
│   ├── configs/
│   └── tests/
├── ios/
│   ├── README.md
│   └── PlantDiseaseDetectorApp/
│       ├── README.md
│       ├── PlantDiseaseDetectorApp.xcodeproj/
│       ├── Package.swift
│       ├── Tests/
│       └── PlantDiseaseDetectorApp/
│           ├── App/
│           ├── Models/
│           ├── ViewModels/
│           ├── Views/
│           ├── Services/
│           ├── Components/
│           ├── Resources/
│           └── Assets.xcassets/
└── docs/
    ├── ios-integration-notes.md
    ├── model-contract.md
    ├── conversion-notes.md
    ├── dataset-notes.md
    ├── troubleshooting.md
    ├── verification-report.md
    └── worktree-plan.md
```

## Requirements

- A local fine-tuned YOLO checkpoint at `models/raw/best.pt`.
- The project Python environments for validation/export.
- Xcode for opening the SwiftUI app.
- Local Core AI SDK verification before replacing the placeholder runtime loader.

## Model Layout

- Local input checkpoint: `models/raw/best.pt`
- Intermediate exports: `models/exported/`
- Future Core AI-ready artifacts: `models/core-ai/`

## Model Conversion Flow

- `convert_to_core_ai.py` exports a raw-output detector asset named `FarmerHelper_YOLO26_RawDetector.aimodel`.
- The converted asset exposes:
  - `raw_boxes`: `[1, 4, 2100]`
  - `raw_scores`: `[1, 38, 2100]`
- Swift postprocessing is intentionally separate so confidence filtering, label mapping, normalization, and class-aware NMS stay transparent and adjustable in the app.

## iOS App Flow

- `PlantDiseaseDetectorApp` already provides the image picker, overlay UI, and runtime status panel.
- `DetectionPostProcessor.swift` now implements the raw YOLO tensor parsing path that the eventual Core AI runtime call will feed.
- `CoreAIPlantDiseaseDetector.swift` remains compile-safe and intentionally does not invent unverified Apple APIs.
- `MockPlantDiseaseDetector.swift` remains the local fallback path until the real runtime loader is confirmed.

## Known Limitations

- The generated `.aimodel` remains local/ignored and is not bundled automatically.
- The Apple runtime entrypoint for `.aimodel` execution is still pending local SDK verification.
- End-to-end Core AI inference inside the app is therefore not yet claimed as verified.

## Verification Status

- Python model validation/export/conversion checks: recorded in `docs/verification-report.md`.
- Swift raw-output postprocessing tests: recorded in `docs/verification-report.md`.
- Xcode-side app build/runtime verification: still pending local developer verification.
