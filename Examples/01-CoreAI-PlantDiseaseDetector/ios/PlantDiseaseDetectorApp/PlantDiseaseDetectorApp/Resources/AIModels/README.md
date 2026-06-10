# AI Models

Place the verified Apple-side converted detector asset in this folder when it exists:

```text
PlantDiseaseDetectorApp/Resources/AIModels/
```

Current status:

1. `best.pt` was validated locally and the model/YAML class order matched exactly (`38` classes).
2. TorchScript and ONNX exports were generated locally, but official Core AI Python tooling was not discoverable.
3. No real `.aimodel` was generated, so no detector model asset is bundled here.
4. `CoreAIPlantDiseaseDetector.swift` therefore falls back to the mock detector path at runtime.

Generated model artifacts should remain local and ignored unless they are intentionally distributed later as release assets or another explicit delivery mechanism.
