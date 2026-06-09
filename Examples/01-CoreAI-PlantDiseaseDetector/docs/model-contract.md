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
