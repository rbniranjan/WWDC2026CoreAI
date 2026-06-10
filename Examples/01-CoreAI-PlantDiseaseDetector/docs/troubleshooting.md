# Troubleshooting

## Python Environment Issues

- If `python` points to an unexpected interpreter, use `python3`.
- A future Python worktree can create and activate a virtual environment before installing dependencies.

## Missing YOLO Checkpoint

- Place the local detector checkpoint at `models/raw/best.pt`.
- Do not commit the checkpoint to Git.

## Missing Core AI Conversion Package

- The actual YOLO export/conversion path is not implemented yet in this base refactor.
- If Apple-side conversion tooling is unavailable later, keep the boundary explicit and do not fake conversion success.

## Xcode / Core AI SDK Not Available

- This repository does not assume Core AI APIs that were not locally verified.
- If Xcode is installed but unusable, complete the Xcode license setup first.

## iOS Model Asset Not Found

- Add the verified converted model asset to `ios/PlantDiseaseDetectorApp/PlantDiseaseDetectorApp/Resources/AIModels/`.
- Ensure the folder contents are included in the app target.

## Mock Fallback Behavior

- If the Core AI runtime path throws an unsupported or missing-model error, the app falls back to `MockPlantDiseaseDetector`.
- The mock result is a placeholder only and is not a real object detector.
