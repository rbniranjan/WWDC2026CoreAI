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
- Exact production class names are still pending confirmation against the real YOLO training data and `best.pt`.
- `configs/full_plant_data.yaml` currently preserves the required 38-index structure with placeholder labels rather than unverified disease names.

Phase 1B-2 additions:

- `run_local_detection.py` writes one-image detection results using this normalized format.
- `create_ios_model_package.py` writes `model_contract.json` and `plant_disease_labels.json` for the iOS handoff package.
- Any future `.aimodel` must preserve this detection contract or document any conversion-side post-processing changes explicitly.

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
