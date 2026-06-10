from __future__ import annotations

from collections.abc import Sequence
from math import isfinite
from typing import Any


def _to_scalar(value: Any) -> Any:
    if hasattr(value, "item") and callable(value.item):
        return value.item()
    return value


def _to_list(value: Any) -> Any:
    if hasattr(value, "tolist") and callable(value.tolist):
        return value.tolist()
    return value


def clamp_confidence(value: float) -> float:
    return max(0.0, min(1.0, float(value)))


def validate_bbox_xyxy_pixels(bbox: Sequence[Any]) -> list[float]:
    if len(bbox) != 4:
        raise ValueError("Bounding box must contain exactly four values: [x1, y1, x2, y2]")

    values = [float(item) for item in bbox]
    if not all(isfinite(value) for value in values):
        raise ValueError("Bounding box values must be finite numbers")

    x1, y1, x2, y2 = values
    if x2 < x1 or y2 < y1:
        raise ValueError("Bounding box must satisfy x2 >= x1 and y2 >= y1")

    return values


def _extract_value(raw_detection: Any, *names: str) -> Any:
    if isinstance(raw_detection, dict):
        for name in names:
            if name in raw_detection:
                return raw_detection[name]
    else:
        for name in names:
            if hasattr(raw_detection, name):
                return getattr(raw_detection, name)
    raise KeyError(f"Missing required field; tried: {', '.join(names)}")


def normalize_detection(raw_detection: Any, class_names: list[str] | None = None) -> dict[str, Any]:
    class_id = int(_to_scalar(_extract_value(raw_detection, "class_id", "cls")))
    confidence = clamp_confidence(float(_to_scalar(_extract_value(raw_detection, "confidence", "conf"))))
    bbox = validate_bbox_xyxy_pixels(_to_list(_extract_value(raw_detection, "bbox_xyxy_pixels", "bbox", "xyxy")))

    try:
        class_name = str(_to_scalar(_extract_value(raw_detection, "class_name", "name")))
    except KeyError:
        if class_names is None:
            raise ValueError("class_name is missing and no class_names list was provided") from None
        try:
            class_name = class_names[class_id]
        except IndexError as error:
            raise ValueError(f"class_id {class_id} is out of range for class_names") from error

    return {
        "class_id": class_id,
        "class_name": class_name,
        "confidence": confidence,
        "bbox_xyxy_pixels": bbox,
    }


def normalize_ultralytics_box(box: Any, class_names: list[str]) -> dict[str, Any]:
    xyxy = _to_list(box.xyxy)
    if isinstance(xyxy, list) and len(xyxy) == 1 and isinstance(xyxy[0], list):
        xyxy = xyxy[0]

    return normalize_detection(
        {
            "cls": _to_scalar(box.cls),
            "conf": _to_scalar(box.conf),
            "xyxy": xyxy,
        },
        class_names=class_names,
    )
