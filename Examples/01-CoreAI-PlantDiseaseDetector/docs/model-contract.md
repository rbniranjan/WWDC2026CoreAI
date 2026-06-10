# Model Contract

## Input

- image: RGB image
- expected size: `320x320` initially, configurable later
- normalization: YOLO / Ultralytics default preprocessing unless changed by the export target

## Output Detection Object

```json
{
  "class_id": 0,
  "class_name": "Apple___Apple_scab",
  "confidence": 0.91,
  "bbox_xyxy_pixels": [42, 58, 270, 301]
}
```

## Core AI Raw Outputs

The Core AI asset intentionally exposes raw detector tensors instead of final postprocessed detections:

- `raw_boxes`: shape `[1, 4, 2100]`
- `raw_scores`: shape `[1, 38, 2100]`

Swift is responsible for:

- confidence filtering
- class winner selection
- any non-maximum suppression policy
- conversion into `PlantDiseaseDetection` values for overlay/UI rendering

Current Phase 1B-1 note:

- The Python output adapter normalizes detections into this shape.
- The final `38` class names were validated locally against `best.pt`.
- The model class order and YAML class order matched exactly.

Phase 1B-2 additions:

- `run_local_detection.py` writes one-image detection results using this normalized format when a sample image is available.
- `create_ios_model_package.py` writes `model_contract.json` and `plant_disease_labels.json` for the iOS handoff package.
- The generated `.aimodel` now preserves raw detector outputs so iOS can apply postprocessing explicitly in Swift.

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
- `iou_threshold`: `0.45` if NMS / post-processing is required
