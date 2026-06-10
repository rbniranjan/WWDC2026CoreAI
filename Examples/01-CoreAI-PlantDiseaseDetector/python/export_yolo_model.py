from __future__ import annotations

import argparse
import importlib
import json
import shutil
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from pipeline_config import DEFAULT_EXPORTED_DIR, DEFAULT_MODEL_PATH, resolve_path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Export a local YOLO detector to intermediate artifacts.")
    parser.add_argument("--model-path", type=Path, default=DEFAULT_MODEL_PATH, help="Path to best.pt")
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_EXPORTED_DIR, help="Directory for exported artifacts")
    parser.add_argument("--formats", type=str, default="torchscript,onnx", help="Comma-separated export formats")
    parser.add_argument("--imgsz", type=int, default=320, help="Export image size")
    parser.add_argument("--nms", action="store_true", help="Enable NMS during export if supported")
    return parser.parse_args()


def discover_output_paths(before: set[Path], after_dir: Path) -> list[str]:
    after = {path for path in after_dir.iterdir()} if after_dir.exists() else set()
    created = sorted(str(path.resolve()) for path in after - before if path.is_file())
    return created


def write_metadata(output_dir: Path, metadata: dict[str, Any]) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / "export_metadata.json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")


def normalize_export_path(path_str: str, output_dir: Path) -> str:
    source_path = Path(path_str).resolve()
    output_dir = output_dir.resolve()
    if not source_path.exists() or source_path.parent == output_dir:
        return str(source_path)

    destination = output_dir / source_path.name
    if destination.exists():
        destination.unlink()
    shutil.move(str(source_path), str(destination))
    return str(destination.resolve())


def main() -> int:
    args = parse_args()
    model_path = resolve_path(args.model_path)
    output_dir = resolve_path(args.output_dir)
    formats = [item.strip() for item in args.formats.split(",") if item.strip()]

    metadata: dict[str, Any] = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "source_model_path": str(model_path),
        "export_formats_attempted": formats,
        "successful_outputs": [],
        "failed_outputs": [],
        "imgsz": args.imgsz,
        "nms": bool(args.nms),
        "ultralytics_version": None,
    }

    if not model_path.exists():
        metadata["failed_outputs"].append({"format": "all", "reason": f"Model not found: {model_path}"})
        write_metadata(output_dir, metadata)
        print(f"FAIL: model not found: {model_path}")
        return 1

    try:
        ultralytics = importlib.import_module("ultralytics")
    except ModuleNotFoundError:
        metadata["failed_outputs"].append(
            {"format": "all", "reason": "ultralytics is not installed in this environment"}
        )
        write_metadata(output_dir, metadata)
        print("FAIL: ultralytics is not installed in this environment")
        return 1

    metadata["ultralytics_version"] = getattr(ultralytics, "__version__", "unknown")
    output_dir.mkdir(parents=True, exist_ok=True)
    model = ultralytics.YOLO(str(model_path))
    exit_code = 0

    for format_name in formats:
        before = {path for path in output_dir.iterdir()} if output_dir.exists() else set()
        try:
            export_result = model.export(format=format_name, imgsz=args.imgsz, nms=args.nms, project=str(output_dir), name="")
            created_paths = discover_output_paths(before, output_dir)
            if isinstance(export_result, str):
                created_paths.append(normalize_export_path(export_result, output_dir))
            created_paths = sorted(set(created_paths))
            metadata["successful_outputs"].append({"format": format_name, "paths": created_paths})
            print(f"PASS: exported {format_name}")
        except Exception as error:
            exit_code = 1
            metadata["failed_outputs"].append({"format": format_name, "reason": str(error)})
            print(f"FAIL: export {format_name}: {error}")

    write_metadata(output_dir, metadata)
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
