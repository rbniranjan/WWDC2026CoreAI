# Conversion Notes

## Intended Source Model

- Local YOLO checkpoint: `models/raw/best.pt`
- This file is expected locally and is intentionally excluded from Git.

## Planned Output Locations

- Intermediate exports: `models/exported/`
- Core AI-ready outputs: `models/core-ai/`

## Core AI Conversion Status

- Current status: scaffold/base refactor only.
- Exact Apple Core AI conversion APIs were not verified in this environment.
- No claim is made that a YOLO detector export or a final Core AI model asset was produced.

## Exact TODOs Requiring Local Apple SDK Verification

1. Verify the official Apple Core AI conversion/runtime APIs in the installed Xcode/SDK.
2. Implement the YOLO export pipeline in the Python worktree.
3. Replace the TODO runtime placeholder in `ios/PlantLeafClassifierApp/PlantLeafClassifierApp/CoreAIPlantDiseaseDetector.swift`.
4. Confirm the expected model bundle format and output post-processing requirements for detections.
