# AI Models

Place the verified Apple-side converted detector asset in this folder when it exists:

```text
PlantDiseaseDetectorApp/Resources/AIModels/
```

Current status:

1. `best.pt` was validated locally and the model/YAML class order matched exactly (`38` classes).
2. TorchScript and ONNX exports were generated locally.
3. A raw-output Core AI asset was generated locally at:
   `Examples/01-CoreAI-PlantDiseaseDetector/models/core-ai/FarmerHelper_YOLO26_RawDetector.aimodel`
4. That asset is intentionally kept local/ignored and is not bundled automatically here.
5. `DetectionPostProcessor.swift` is already prepared to consume the asset's raw outputs:
   - `raw_boxes` `[1, 4, 2100]`
   - `raw_scores` `[1, 38, 2100]`
6. `CoreAIPlantDiseaseDetector.swift` therefore still falls back to the mock detector path at runtime until a local developer copies the asset in and finishes the verified runtime loader/inference path.

Generated model artifacts should remain local and ignored unless they are intentionally distributed later as release assets or another explicit delivery mechanism.
