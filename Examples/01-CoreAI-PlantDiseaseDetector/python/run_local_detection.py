from __future__ import annotations

import argparse
import importlib
import json
from pathlib import Path

from pipeline_config import DEFAULT_DATA_YAML, DEFAULT_MODEL_PATH, resolve_path
from plant_disease_labels import load_class_names
from yolo_output_adapter import normalize_ultralytics_box


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run one local YOLO detection and save normalized output JSON.")
    parser.add_argument("--model-path", type=Path, default=DEFAULT_MODEL_PATH, help="Path to best.pt")
    parser.add_argument("--image-path", type=Path, required=True, help="Path to an input image")
    parser.add_argument("--data-yaml", type=Path, default=DEFAULT_DATA_YAML, help="Path to dataset YAML")
    parser.add_argument("--output-json", type=Path, required=True, help="Path to write normalized detection JSON")
    parser.add_argument("--conf", type=float, default=0.35, help="Confidence threshold")
    parser.add_argument("--iou", type=float, default=0.45, help="IoU threshold")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    model_path = resolve_path(args.model_path)
    image_path = resolve_path(args.image_path)
    data_yaml_path = resolve_path(args.data_yaml)
    output_json_path = resolve_path(args.output_json)

    if not model_path.exists():
        print(f"FAIL: model not found: {model_path}")
        return 1
    if not image_path.exists():
        print(f"FAIL: image not found: {image_path}")
        return 1
    if not data_yaml_path.exists():
        print(f"FAIL: dataset YAML not found: {data_yaml_path}")
        return 1

    try:
        importlib.import_module("torch")
        ultralytics = importlib.import_module("ultralytics")
    except ModuleNotFoundError as error:
        print(f"FAIL: missing dependency: {error.name}")
        return 1

    class_names = load_class_names(data_yaml_path)
    model = ultralytics.YOLO(str(model_path))
    results = model.predict(source=str(image_path), conf=args.conf, iou=args.iou, verbose=False)

    detections: list[dict[str, object]] = []
    for result in results:
        boxes = getattr(result, "boxes", None)
        if boxes is None:
            continue
        for box in boxes:
            detections.append(normalize_ultralytics_box(box, class_names))

    payload = {
        "image_path": str(image_path),
        "detections": detections,
    }
    output_json_path.parent.mkdir(parents=True, exist_ok=True)
    output_json_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(f"Saved detection JSON: {output_json_path}")
    print(f"Detections: {len(detections)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

