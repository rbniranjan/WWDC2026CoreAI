from __future__ import annotations

from dataclasses import dataclass

import pytest

from yolo_output_adapter import clamp_confidence, normalize_detection, validate_bbox_xyxy_pixels


@dataclass
class RawDetection:
    cls: int
    conf: float
    xyxy: list[float]
    name: str


def test_clamp_confidence_bounds() -> None:
    assert clamp_confidence(-0.5) == 0.0
    assert clamp_confidence(0.25) == 0.25
    assert clamp_confidence(1.4) == 1.0


def test_validate_bbox_rejects_invalid_shape() -> None:
    with pytest.raises(ValueError, match="exactly four"):
        validate_bbox_xyxy_pixels([1.0, 2.0, 3.0])


def test_validate_bbox_rejects_invalid_order() -> None:
    with pytest.raises(ValueError, match="x2 >= x1"):
        validate_bbox_xyxy_pixels([5.0, 4.0, 3.0, 10.0])


def test_normalize_detection_from_dict() -> None:
    detection = normalize_detection(
        {
            "class_id": 0,
            "class_name": "Apple___Apple_scab",
            "confidence": 1.2,
            "bbox_xyxy_pixels": [42, 58, 270, 301],
        }
    )

    assert detection == {
        "class_id": 0,
        "class_name": "Apple___Apple_scab",
        "confidence": 1.0,
        "bbox_xyxy_pixels": [42.0, 58.0, 270.0, 301.0],
    }


def test_normalize_detection_from_object_uses_label_list() -> None:
    raw = RawDetection(cls=1, conf=0.87, xyxy=[10, 20, 30, 40], name="")

    detection = normalize_detection(raw, class_names=["a", "b"])

    assert detection["class_id"] == 1
    assert detection["class_name"] == ""
    assert detection["confidence"] == 0.87
    assert detection["bbox_xyxy_pixels"] == [10.0, 20.0, 30.0, 40.0]


def test_missing_class_name_can_use_label_list() -> None:
    detection = normalize_detection(
        {"cls": 1, "conf": 0.3, "xyxy": [1, 2, 3, 4]},
        class_names=["first", "second"],
    )

    assert detection["class_name"] == "second"


def test_missing_class_name_without_label_list_fails() -> None:
    with pytest.raises(ValueError, match="class_name is missing"):
        normalize_detection({"cls": 1, "conf": 0.3, "xyxy": [1, 2, 3, 4]})

