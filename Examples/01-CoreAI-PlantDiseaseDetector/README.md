# Core AI Plant Disease Detector

This example is being repositioned as an object detection demo around a fine-tuned YOLO checkpoint.

Target workflow:

1. Start from a local YOLO model at `models/raw/best.pt`.
2. Add an export/conversion boundary for Apple on-device packaging.
3. Produce a Core AI-ready model asset once the official SDK path is verified.
4. Visualize detections in a SwiftUI app with bounding boxes, class labels, and confidence.

## Current Status

- Scaffold/base refactor only.
- Python YOLO pipeline is intentionally not implemented yet.
- iOS detection UI is intentionally not implemented yet.
- Exact Core AI APIs must still be verified against Xcode 27 / the Core AI SDK before real integration code is added.

## What This Example Is For

- Align the repository structure with a detector workflow instead of a classifier workflow.
- Define the shared model contract between Python and iOS early.
- Reserve model directories for local checkpoints, exported artifacts, and Core AI-ready outputs.
- Keep the current app and Python files in safe placeholder status for later worktrees.

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
│   ├── requirements.txt
│   ├── generate_sample_dataset.py
│   ├── train_leaf_classifier.py
│   ├── convert_to_core_ai.py
│   ├── predict_local.py
│   ├── leaf_classifier_model.py
│   ├── data/
│   │   └── .gitkeep
│   ├── models/
│   │   └── .gitkeep
│   └── sample_images/
│       └── .gitkeep
├── ios/
│   ├── README.md
│   └── PlantLeafClassifierApp/
│       ├── README.md
│       ├── PlantLeafClassifierApp.xcodeproj/
│       └── PlantLeafClassifierApp/
│           ├── PlantLeafClassifierApp.swift
│           ├── ContentView.swift
│           ├── PlantDiseaseDetectionViewModel.swift
│           ├── LeafImagePicker.swift
│           ├── CoreAIPlantDiseaseDetector.swift
│           ├── MockPlantDiseaseDetector.swift
│           ├── Info.plist
│           ├── Assets.xcassets/
│           └── Models/
│               └── README.md
└── docs/
    ├── model-contract.md
    ├── conversion-notes.md
    ├── dataset-notes.md
    ├── troubleshooting.md
    ├── verification-report.md
    └── worktree-plan.md
```

## Requirements

- A local fine-tuned YOLO checkpoint placed at `models/raw/best.pt`.
- Python 3.10+ for the future export pipeline work.
- Xcode for opening the included SwiftUI scaffold.
- Later verification of the official Core AI conversion/runtime path before production integration.

## Model Layout

- Local input checkpoint: `models/raw/best.pt`
- Intermediate exports: `models/exported/`
- Future Core AI-ready artifacts: `models/core-ai/`

## Model Conversion Flow

- The eventual pipeline will convert a YOLO `.pt` detector into Apple-compatible artifacts.
- The exact Core AI conversion path is intentionally left unresolved until the SDK/API surface is verified locally.
- No claim is made that the current scaffold performs real YOLO export or Core AI conversion.

## iOS App Flow

- `PlantLeafClassifierApp.xcodeproj` remains a lightweight scaffold only.
- The current Swift files are placeholders that will be refactored into a real detector UI in a separate worktree.
- Future iOS work will focus on image loading, running detection, and drawing bounding boxes.

## Known Limitations

- No YOLO Python implementation is included yet.
- No SwiftUI bounding-box detection UI is included yet.
- Apple Core AI SDK symbols are still unverified in this environment.
- The legacy classifier-oriented placeholder files under `python/` and `ios/` have not been deeply rewritten in this refactor.

## Verification Status

- Folder rename and model layout update: completed.
- Lightweight file-tree and Python syntax checks: recorded in `docs/verification-report.md`.
- Python YOLO pipeline: not implemented yet.
- iOS detector UI: not implemented yet.
