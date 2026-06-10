# AI Models

This folder is the local app-resource destination for the Core AI detector asset.

## Expected Local Model

```text
PlantDiseaseDetectorApp/Resources/AIModels/FarmerHelper_YOLO26_RawDetector.aimodel
```

The source model is expected locally at:

```text
Examples/01-CoreAI-PlantDiseaseDetector/models/core-ai/FarmerHelper_YOLO26_RawDetector.aimodel
```

## How To Copy It Locally

Use the helper script:

```text
Examples/01-CoreAI-PlantDiseaseDetector/scripts/sync-local-aimodel.sh
```

That script:

- copies the local generated `.aimodel` into this folder
- fails clearly if the source model is missing
- does not generate or download the model
- keeps the copied model local-only

## Model Contract

The app expects a raw-output detector asset:

- `raw_boxes` `[1, 4, 2100]`
- `raw_scores` `[1, 38, 2100]`

Swift postprocessing in `DetectionPostProcessor.swift` turns those outputs into final detections.

## Model Artifacts

This `.aimodel` is intentionally not committed. The same policy applies to the trained `best.pt` model and generated conversion metadata.

If another developer needs the trained `best.pt` or generated `.aimodel` for testing or review, they should open a GitHub issue, leave a repository comment, or contact the repository owner by email if a contact address is available.

## If The Model Is Missing

The app still compiles and runs. `CoreAIPlantDiseaseDetector.swift` stays behind a compile-safe placeholder boundary, and the UI falls back to the mock detector path until a local model is synced here.
