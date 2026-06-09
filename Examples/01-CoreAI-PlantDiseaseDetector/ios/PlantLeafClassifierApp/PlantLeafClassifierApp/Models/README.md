# Models Directory

Place the verified Apple-side converted model asset in this folder before wiring up real on-device inference.

Expected use:

1. Complete the future Python YOLO export pipeline.
2. Run the future conversion/export step.
3. Replace the TODO runtime adapter in `CoreAIPlantDiseaseDetector.swift` with verified Apple Core AI APIs.
4. Add the resulting model asset to this directory and include it in the Xcode target.
