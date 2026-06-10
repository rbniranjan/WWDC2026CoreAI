# Model Contract

## Input

- `image`
- shape: `[1, 3, 320, 320]`
- layout: `NCHW`
- dtype: `float32`
- semantic: RGB image resized into model input space

## Core AI Raw Outputs

The Core AI asset intentionally exposes raw detector tensors instead of final postprocessed detections:

- `raw_boxes`: shape `[1, 4, 2100]`
- `raw_scores`: shape `[1, 38, 2100]`
- `raw_boxes` semantic: `xyxy` pixel coordinates in the `320x320` model input space
- `raw_scores` semantic: per-class detector scores for each anchor

Swift is responsible for:

- validating the label catalog count and order
- confidence filtering
- class winner selection per anchor
- `xyxy` pixel to normalized `CGRect` conversion
- class-aware non-maximum suppression
- conversion into `PlantDiseaseDetection` values for overlay/UI rendering

Current verified status:

- The final `38` class names were validated locally against `best.pt`.
- The model class order and YAML class order matched exactly.
- `create_ios_model_package.py` writes `model_contract.json` and `plant_disease_labels.json` for the iOS handoff package.
- The generated `.aimodel` preserves raw detector outputs so iOS can apply postprocessing explicitly in Swift.
- `DetectionPostProcessor.swift` implements the app-side interpretation of those tensors.

## Verified Labels

- `classes_count`: `38`
- `plant_disease_labels.json` in the iOS handoff package contains the real class list copied from the validated YAML/model pair.
- No placeholder label markers remain in the active config or iOS handoff JSON.

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

## Initial Runtime Defaults

- `confidence_threshold`: `0.35`
- `iou_threshold`: `0.45`
- runtime entrypoint name: `detect_raw`
