# Model Contract

## Overview

This example uses a raw-output YOLO detector contract between the Python conversion flow and the Swift iOS app.

Flow:

```text
best.pt
-> convert_to_core_ai.py
-> FarmerHelper_YOLO26_RawDetector.aimodel
-> raw_boxes [1, 4, 2100]
-> raw_scores [1, 38, 2100]
-> DetectionPostProcessor.swift
-> final detections
```

## Input

- `image`
- shape: `[1, 3, 320, 320]`
- layout: `NCHW`
- dtype: `float32`
- semantic: RGB image resized into model input space

## Outputs

- `raw_boxes`
  - shape: `[1, 4, 2100]`
  - semantic: `xyxy` pixel coordinates in `320x320` model input space
- `raw_scores`
  - shape: `[1, 38, 2100]`
  - semantic: per-class detector scores for each anchor

## Class / Threshold Defaults

- class count: `38`
- confidence threshold: `0.35`
- IoU threshold: `0.45`
- runtime entrypoint: `detect_raw`

## Why The Contract Uses Raw Outputs

Direct YOLO end-to-end postprocessing conversion hit an unsupported `aten.remainder.Scalar` path. The verified conversion path disables YOLO end-to-end postprocessing and exports only raw detector tensors.

That keeps the app-side logic explicit and testable.

## Swift Responsibilities

Swift owns:

- validating the label catalog count and order
- selecting the best class per anchor
- applying the confidence threshold
- converting `xyxy` pixels into normalized `CGRect`
- applying class-aware NMS
- producing final `PlantDiseaseDetection` values for overlay/UI rendering

## Verified Labels

- `classes_count`: `38`
- The label order in `plant_disease_labels.json` matched the validated YAML/model pair exactly.
- No placeholder label markers remain in the active handoff files.

## iOS Equivalent

```swift
struct PlantDiseaseDetection: Identifiable {
    let id: UUID
    let classId: Int
    let className: String
    let confidence: Double
    let boundingBox: CGRect
}
```

## Related Files

- Python conversion: `python/convert_to_core_ai.py`
- Local contract copy for iOS: `ios/PlantDiseaseDetectorApp/PlantDiseaseDetectorApp/Resources/ModelContract/model_contract.json`
- Swift postprocessing: `ios/PlantDiseaseDetectorApp/PlantDiseaseDetectorApp/Services/Inference/DetectionPostProcessor.swift`
