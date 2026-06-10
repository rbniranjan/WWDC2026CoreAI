from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path

from pipeline_config import (
    DEFAULT_CORE_AI_DIR,
    DEFAULT_DATA_YAML,
    DEFAULT_EXPORT_CONFIG,
    DEFAULT_IOS_PACKAGE_DIR,
    load_export_config,
    resolve_path,
)
from plant_disease_labels import load_class_names


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Create an iOS handoff package for the detector model.")
    parser.add_argument("--data-yaml", type=Path, default=DEFAULT_DATA_YAML, help="Dataset YAML path")
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_IOS_PACKAGE_DIR, help="Output package directory")
    parser.add_argument("--core-ai-dir", type=Path, default=DEFAULT_CORE_AI_DIR, help="Core AI artifact directory")
    return parser.parse_args()


def find_aimodel(core_ai_dir: Path) -> Path | None:
    for path in sorted(core_ai_dir.glob("*.aimodel")):
        return path
    return None


def write_readme(output_dir: Path, aimodel_path: Path | None) -> None:
    if aimodel_path is None:
        aimodel_note = (
            "No `.aimodel` was included. Core AI conversion is still blocked or has not been run successfully."
        )
    else:
        aimodel_note = f"Included Core AI model artifact: `{aimodel_path.name}`"

    content = (
        "# iOS Model Package\n\n"
        "Generated for the Swift/iOS integration handoff.\n\n"
        "Included files:\n\n"
        "- `model_contract.json`\n"
        "- `plant_disease_labels.json`\n"
        "- `README.md`\n\n"
        f"{aimodel_note}\n"
    )
    (output_dir / "README.md").write_text(content, encoding="utf-8")


def main() -> int:
    args = parse_args()
    data_yaml_path = resolve_path(args.data_yaml)
    output_dir = resolve_path(args.output_dir)
    core_ai_dir = resolve_path(args.core_ai_dir)

    class_names = load_class_names(data_yaml_path)
    export_config = load_export_config(DEFAULT_EXPORT_CONFIG)
    output_dir.mkdir(parents=True, exist_ok=True)

    model_contract = {
        "model_name": export_config["model_name"],
        "task": export_config["task"],
        "input_image_size": int(export_config["input_image_size"]),
        "classes_count": len(class_names),
        "confidence_threshold": float(export_config["confidence_threshold"]),
        "iou_threshold": float(export_config["iou_threshold"]),
        "output_format": {
            "bbox": "xyxy_pixels",
            "class_id": "int",
            "class_name": "string",
            "confidence": "float",
        },
    }
    (output_dir / "model_contract.json").write_text(json.dumps(model_contract, indent=2) + "\n", encoding="utf-8")

    labels_payload = {
        "classes_count": len(class_names),
        "labels": [{"class_id": index, "class_name": name} for index, name in enumerate(class_names)],
    }
    (output_dir / "plant_disease_labels.json").write_text(
        json.dumps(labels_payload, indent=2) + "\n", encoding="utf-8"
    )

    aimodel_path = find_aimodel(core_ai_dir) if core_ai_dir.exists() else None
    if aimodel_path is not None:
        shutil.copy2(aimodel_path, output_dir / aimodel_path.name)

    write_readme(output_dir, aimodel_path)
    print(f"Created iOS package: {output_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

