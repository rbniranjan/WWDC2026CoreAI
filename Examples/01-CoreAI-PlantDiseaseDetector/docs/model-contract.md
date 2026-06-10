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

Current Phase 1B-1 note:

- The Python output adapter normalizes detections into this shape.
- The final `38` class names were validated locally against `best.pt`.
- The model class order and YAML class order matched exactly.

Phase 1B-2 additions:

- `run_local_detection.py` writes one-image detection results using this normalized format when a sample image is available.
- `create_ios_model_package.py` writes `model_contract.json` and `plant_disease_labels.json` for the iOS handoff package.
- Any future `.aimodel` must preserve this detection contract or document any conversion-side post-processing changes explicitly.

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
