from __future__ import annotations

import argparse
import importlib.util
from pathlib import Path


PYTHON_DIR = Path(__file__).resolve().parent
DEFAULT_MODEL_PATH = Path("../models/raw/best.pt")
DEFAULT_DATA_YAML = Path("configs/full_plant_data.yaml")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Inspect a local YOLO detector checkpoint against the data YAML.")
    parser.add_argument("--model-path", type=Path, default=DEFAULT_MODEL_PATH, help="Path to best.pt")
    parser.add_argument("--data-yaml", type=Path, default=DEFAULT_DATA_YAML, help="Path to dataset YAML")
    return parser.parse_args()


def resolve_path(path: Path) -> Path:
    return path if path.is_absolute() else (PYTHON_DIR / path).resolve()


def main() -> int:
    args = parse_args()
    model_path = resolve_path(args.model_path)
    data_yaml_path = resolve_path(args.data_yaml)

    if not data_yaml_path.exists():
        print(f"FAIL: dataset YAML not found: {data_yaml_path}")
        return 1

    try:
        from plant_disease_labels import load_class_names, names_value_to_list

        yaml_class_names = load_class_names(data_yaml_path)
    except Exception as error:
        print(f"FAIL: could not load class names from YAML: {error}")
        return 1

    print(f"YAML class count: {len(yaml_class_names)}")
    print("YAML class names:")
    for index, name in enumerate(yaml_class_names):
        print(f"  {index}: {name}")

    if importlib.util.find_spec("ultralytics") is None:
        print("FAIL: 'ultralytics' is not installed; cannot inspect the YOLO checkpoint.")
        return 1

    if not model_path.exists():
        print(f"FAIL: YOLO checkpoint not found: {model_path}")
        print("Place the local fine-tuned model at ../models/raw/best.pt and re-run this script.")
        return 1

    from ultralytics import YOLO  # type: ignore

    model = YOLO(str(model_path))
    model_names = getattr(model, "names", None)
    if model_names is None:
        print("FAIL: YOLO model did not expose a 'names' attribute.")
        return 1

    model_class_names = names_value_to_list(model_names)
    print(f"Model class count: {len(model_class_names)}")
    print("Model class names:")
    for index, name in enumerate(model_class_names):
        print(f"  {index}: {name}")

    if model_class_names != yaml_class_names:
        print("FAIL: model class names do not match configs/full_plant_data.yaml")
        for index, (yaml_name, model_name) in enumerate(zip(yaml_class_names, model_class_names)):
            if yaml_name != model_name:
                print(f"  mismatch at index {index}: yaml={yaml_name!r} model={model_name!r}")
        if len(model_class_names) != len(yaml_class_names):
            print(f"  count mismatch: yaml={len(yaml_class_names)} model={len(model_class_names)}")
        return 1

    print("PASS: model classes match the dataset YAML exactly.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
