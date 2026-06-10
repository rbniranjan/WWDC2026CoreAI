from __future__ import annotations

import argparse
import importlib
import importlib.util
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from pipeline_config import DEFAULT_CORE_AI_DIR, DEFAULT_DATA_YAML, DEFAULT_MODEL_PATH, resolve_path


CORE_AI_CANDIDATE_MODULES = [
    "core_ai",
    "coreai",
    "core_ai_torch",
    "apple_core_ai",
    "apple_coreai",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Attempt Core AI model conversion if official tooling is available.")
    parser.add_argument("--model-path", type=Path, default=DEFAULT_MODEL_PATH, help="Path to best.pt")
    parser.add_argument("--exported-model-path", type=Path, default=None, help="Path to a TorchScript/ONNX export")
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_CORE_AI_DIR, help="Directory for Core AI outputs")
    parser.add_argument("--data-yaml", type=Path, default=DEFAULT_DATA_YAML, help="Dataset YAML path")
    parser.add_argument("--imgsz", type=int, default=320, help="Input image size")
    return parser.parse_args()


def discover_core_ai_modules() -> list[str]:
    return [name for name in CORE_AI_CANDIDATE_MODULES if importlib.util.find_spec(name) is not None]


def default_exported_model_path() -> Path | None:
    candidates = [
        DEFAULT_CORE_AI_DIR.parent / "exported" / "best.torchscript",
        DEFAULT_CORE_AI_DIR.parent / "exported" / "best.onnx",
    ]
    for path in candidates:
        if path.exists():
            return path.resolve()
    return None


def write_metadata(output_dir: Path, metadata: dict[str, Any]) -> Path:
    output_dir.mkdir(parents=True, exist_ok=True)
    metadata_path = output_dir / "core_ai_conversion_metadata.json"
    metadata_path.write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    return metadata_path


def main() -> int:
    args = parse_args()
    model_path = resolve_path(args.model_path)
    exported_model_path = resolve_path(args.exported_model_path) if args.exported_model_path else default_exported_model_path()
    output_dir = resolve_path(args.output_dir)
    data_yaml_path = resolve_path(args.data_yaml)
    discovered_modules = discover_core_ai_modules()

    metadata: dict[str, Any] = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "status": "blocked",
        "reason": "Official Core AI PyTorch Extensions not installed or not discoverable in this environment",
        "model_path": str(model_path),
        "exported_model_path": str(exported_model_path) if exported_model_path else None,
        "data_yaml": str(data_yaml_path),
        "imgsz": args.imgsz,
        "discovered_core_ai_modules": discovered_modules,
        "generated_aimodel": None,
    }

    if discovered_modules:
        metadata["reason"] = (
            "Candidate Core AI-related modules were discovered, but no verified conversion API is implemented in this "
            "repository yet. Manual SDK verification is still required."
        )
        try:
            for module_name in discovered_modules:
                importlib.import_module(module_name)
        except Exception as error:
            metadata["reason"] += f" Import attempt failed: {error}"

    metadata_path = write_metadata(output_dir, metadata)
    print(f"Wrote conversion metadata: {metadata_path}")
    print("Core AI conversion blocked.")
    print("Next steps:")
    print("1. Install or use Xcode 27 with the official Core AI Python tooling.")
    print("2. Verify the actual Core AI conversion API surface locally.")
    print("3. Re-run this script after wiring the verified conversion path.")
    print("4. Place the final .aimodel into models/core-ai/ for iOS handoff.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

