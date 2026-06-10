from __future__ import annotations

import argparse
import importlib
import importlib.util
import json
import shutil
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import torch

from pipeline_config import DEFAULT_CORE_AI_DIR, DEFAULT_DATA_YAML, DEFAULT_MODEL_PATH, resolve_path
from plant_disease_labels import load_class_names, names_value_to_list


DEFAULT_ASSET_NAME = "FarmerHelper_YOLO26_RawDetector.aimodel"


class YOLORawOutputWrapper(torch.nn.Module):
    def __init__(self, detector_model: torch.nn.Module) -> None:
        super().__init__()
        self.model = detector_model

    def forward(self, image: torch.Tensor) -> tuple[torch.Tensor, torch.Tensor]:
        raw_output = self.model(image)
        raw_preds = raw_output[1]
        return raw_preds["boxes"], raw_preds["scores"]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Convert the YOLO detector to a Core AI raw-output asset.")
    parser.add_argument("--model-path", type=Path, default=DEFAULT_MODEL_PATH, help="Path to best.pt")
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_CORE_AI_DIR, help="Directory for Core AI outputs")
    parser.add_argument("--data-yaml", type=Path, default=DEFAULT_DATA_YAML, help="Dataset YAML path")
    parser.add_argument("--imgsz", type=int, default=320, help="Input image size")
    parser.add_argument("--asset-name", type=str, default=DEFAULT_ASSET_NAME, help="Output .aimodel asset name")
    parser.add_argument("--overwrite", action="store_true", help="Replace an existing output asset if it already exists")
    return parser.parse_args()


def discover_core_ai_modules() -> list[str]:
    candidates = ["coreai_torch", "coreai", "coreai.authoring.asset"]
    return [name for name in candidates if importlib.util.find_spec(name) is not None]


def write_metadata(output_dir: Path, metadata: dict[str, Any]) -> Path:
    output_dir.mkdir(parents=True, exist_ok=True)
    metadata_path = output_dir / "core_ai_conversion_metadata.json"
    metadata_path.write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    return metadata_path


def validate_class_names(model_names: list[str], data_yaml_path: Path | None) -> list[str]:
    if data_yaml_path is None:
        return model_names

    if not data_yaml_path.exists():
        raise FileNotFoundError(f"Dataset YAML not found: {data_yaml_path}")

    yaml_class_names = load_class_names(data_yaml_path)
    if model_names != yaml_class_names:
        mismatches: list[str] = []
        for index, (yaml_name, model_name) in enumerate(zip(yaml_class_names, model_names)):
            if yaml_name != model_name:
                mismatches.append(f"index {index}: yaml={yaml_name!r} model={model_name!r}")
        if len(yaml_class_names) != len(model_names):
            mismatches.append(f"count mismatch: yaml={len(yaml_class_names)} model={len(model_names)}")
        mismatch_text = "; ".join(mismatches) if mismatches else "unknown mismatch"
        raise ValueError(f"Model class names do not match dataset YAML: {mismatch_text}")

    return yaml_class_names


def extract_detect_head(detector_model: torch.nn.Module) -> torch.nn.Module:
    model_layers = getattr(detector_model, "model", None)
    if not isinstance(model_layers, (list, tuple, torch.nn.ModuleList, torch.nn.Sequential)) or not model_layers:
        raise ValueError("YOLO detector model did not expose a final Detect head in model[-1]")
    head = model_layers[-1]
    for attr, value in (("end2end", False), ("export", False), ("format", None)):
        if not hasattr(head, attr):
            raise ValueError(f"Detect head is missing expected attribute '{attr}'")
        setattr(head, attr, value)
    return head


def find_remainder_targets(exported_program: Any) -> list[str]:
    remainder_targets: list[str] = []
    for node in exported_program.graph.nodes:
        target_text = str(node.target)
        if "remainder" in target_text:
            remainder_targets.append(target_text)
    return remainder_targets


def remove_existing_asset(asset_path: Path) -> None:
    if not asset_path.exists():
        return
    if asset_path.is_dir():
        shutil.rmtree(asset_path)
    else:
        asset_path.unlink()


def main() -> int:
    args = parse_args()
    model_path = resolve_path(args.model_path)
    output_dir = resolve_path(args.output_dir)
    data_yaml_path = resolve_path(args.data_yaml) if args.data_yaml else None
    output_dir.mkdir(parents=True, exist_ok=True)
    asset_path = output_dir / args.asset_name

    metadata: dict[str, Any] = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "status": "blocked",
        "reason": None,
        "source_model": str(model_path),
        "generated_aimodel": str(asset_path),
        "input_shape": [1, 3, int(args.imgsz), int(args.imgsz)],
        "output_shapes": None,
        "class_count": None,
        "class_names": [],
        "torch_version": torch.__version__,
        "coreai_torch_version": None,
        "postprocessing_responsibility": "iOS app",
        "confidence_threshold": 0.35,
        "iou_threshold": 0.45,
        "data_yaml": str(data_yaml_path) if data_yaml_path else None,
        "discovered_core_ai_modules": discover_core_ai_modules(),
        "overwrite": bool(args.overwrite),
    }

    if asset_path.exists() and not args.overwrite:
        metadata["status"] = "failed"
        metadata["reason"] = (
            f"Output asset already exists: {asset_path}. Delete it or rerun with --overwrite."
        )
        metadata_path = write_metadata(output_dir, metadata)
        print(f"FAIL: output asset already exists: {asset_path}")
        print("Delete it or rerun with --overwrite.")
        print(f"Wrote conversion metadata: {metadata_path}")
        return 1

    if not model_path.exists():
        metadata["reason"] = f"Model not found: {model_path}"
        metadata_path = write_metadata(output_dir, metadata)
        print(f"FAIL: model not found: {model_path}")
        print(f"Wrote conversion metadata: {metadata_path}")
        return 1

    try:
        from ultralytics import YOLO  # type: ignore
    except ModuleNotFoundError:
        metadata["reason"] = "ultralytics is not installed in this environment"
        metadata_path = write_metadata(output_dir, metadata)
        print("FAIL: ultralytics is not installed in this environment")
        print(f"Wrote conversion metadata: {metadata_path}")
        return 1

    try:
        import coreai_torch  # type: ignore
    except ModuleNotFoundError:
        metadata["reason"] = "Official Core AI PyTorch Extensions not installed or not discoverable in this environment"
        metadata_path = write_metadata(output_dir, metadata)
        print(f"Wrote conversion metadata: {metadata_path}")
        print("Core AI conversion blocked.")
        print("Next steps:")
        print("1. Install or use Xcode 27 with the official Core AI Python tooling.")
        print("2. Verify the actual Core AI conversion API surface locally.")
        print("3. Re-run this script after wiring the verified conversion path.")
        print("4. Place the final .aimodel into models/core-ai/ for iOS handoff.")
        return 0

    metadata["coreai_torch_version"] = getattr(coreai_torch, "__version__", "unknown")

    try:
        yolo = YOLO(str(model_path))
        model_names = names_value_to_list(getattr(yolo, "names", None))
        class_names = validate_class_names(model_names, data_yaml_path)
        metadata["class_count"] = len(class_names)
        metadata["class_names"] = class_names

        detector_model = yolo.model.eval()
        extract_detect_head(detector_model)
        wrapper = YOLORawOutputWrapper(detector_model).eval()

        dummy = torch.randn(*metadata["input_shape"])
        with torch.no_grad():
            raw_boxes, raw_scores = wrapper(dummy)

        metadata["output_shapes"] = [list(raw_boxes.shape), list(raw_scores.shape)]

        exported_program = torch.export.export(wrapper, (dummy,))
        exported_program = exported_program.run_decompositions(coreai_torch.get_decomp_table())

        remainder_targets = find_remainder_targets(exported_program)
        if remainder_targets:
            metadata["status"] = "failed"
            metadata["reason"] = "Unsupported remainder nodes found after decomposition"
            metadata["remainder_nodes"] = remainder_targets
            metadata_path = write_metadata(output_dir, metadata)
            print("FAIL: unsupported remainder nodes were found in the exported graph:")
            for target in remainder_targets:
                print(f"  - {target}")
            print(f"Wrote conversion metadata: {metadata_path}")
            return 1

        converter = coreai_torch.TorchConverter()
        converter.add_exported_program(
            exported_program,
            input_names=["image"],
            output_names=["raw_boxes", "raw_scores"],
            entrypoint_name="detect_raw",
        )
        ai_program = converter.to_coreai()

        if args.overwrite and asset_path.exists():
            remove_existing_asset(asset_path)
        ai_program.save_asset(asset_path)

        metadata["status"] = "success"
        metadata["reason"] = None
        metadata["generated_aimodel"] = str(asset_path)
        metadata_path = write_metadata(output_dir, metadata)

        print(f"Saved Core AI asset: {asset_path}")
        print(f"Wrote conversion metadata: {metadata_path}")
        print("PASS: Core AI raw detector conversion completed.")
        return 0
    except Exception as error:
        metadata["status"] = "failed"
        metadata["reason"] = str(error)
        metadata_path = write_metadata(output_dir, metadata)
        print(f"FAIL: Core AI conversion failed: {error}")
        print(f"Wrote conversion metadata: {metadata_path}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
