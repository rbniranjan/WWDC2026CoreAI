from __future__ import annotations

import argparse
import importlib.util
import json
from pathlib import Path
from typing import Any

import torch

from leaf_classifier_model import build_model


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Prepare Apple-side model conversion artifacts.")
    parser.add_argument("--model-path", type=Path, required=True, help="Path to the PyTorch checkpoint.")
    parser.add_argument(
        "--class-mapping-path",
        type=Path,
        default=None,
        help="Optional class mapping path. Defaults to the checkpoint directory's class_mapping.json.",
    )
    parser.add_argument("--output-dir", type=Path, required=True, help="Directory for converted outputs.")
    return parser.parse_args()


def export_torchscript(checkpoint: dict[str, Any], output_dir: Path) -> Path:
    image_size = int(checkpoint.get("image_size", 224))
    model = build_model(image_size=image_size)
    model.load_state_dict(checkpoint["state_dict"])
    model.eval()

    example_input = torch.randn(1, 3, image_size, image_size)
    scripted = torch.jit.trace(model, example_input)
    output_path = output_dir / "leaf_classifier_torchscript.pt"
    scripted.save(str(output_path))
    return output_path


def try_export_coreml(output_dir: Path, scripted_model_path: Path, image_size: int) -> tuple[bool, str]:
    if importlib.util.find_spec("coremltools") is None:
        return False, "coremltools is not installed in this environment."

    import coremltools as ct  # type: ignore

    mlmodel = ct.convert(
        str(scripted_model_path),
        convert_to="mlprogram",
        inputs=[ct.ImageType(name="image", shape=(1, 3, image_size, image_size))],
    )
    output_path = output_dir / "leaf_classifier.mlpackage"
    mlmodel.save(str(output_path))
    return True, f"Saved Core ML package to {output_path}"


def main() -> None:
    args = parse_args()
    if not args.model_path.exists():
        raise FileNotFoundError(f"Model checkpoint not found: {args.model_path}")

    class_mapping_path = args.class_mapping_path or args.model_path.parent / "class_mapping.json"
    if not class_mapping_path.exists():
        raise FileNotFoundError(f"Class mapping not found: {class_mapping_path}")

    args.output_dir.mkdir(parents=True, exist_ok=True)
    checkpoint = torch.load(args.model_path, map_location="cpu")
    class_mapping = json.loads(class_mapping_path.read_text(encoding="utf-8"))
    image_size = int(checkpoint.get("image_size", 224))

    scripted_path = export_torchscript(checkpoint, args.output_dir)
    print(f"Exported TorchScript artifact: {scripted_path}")

    # TODO(Core AI SDK verification):
    # Replace this adapter with the official Apple Core AI conversion API once
    # Xcode 27/Core AI Python tooling is available in the local environment.
    coreml_exported, message = try_export_coreml(args.output_dir, scripted_path, image_size)
    print(message)

    report = {
        "input_checkpoint": str(args.model_path),
        "class_mapping_path": str(class_mapping_path),
        "class_mapping": class_mapping,
        "image_size": image_size,
        "torchscript_output": str(scripted_path),
        "coreml_exported": coreml_exported,
        "notes": [
            "This script did not verify Apple Core AI SDK-specific conversion APIs locally.",
            "Place the verified Apple-side model asset into ios/PlantLeafClassifierApp/PlantLeafClassifierApp/Models/ after conversion.",
        ],
        "next_steps_if_core_ai_sdk_missing": [
            "Install or verify the official Apple Core AI conversion tooling when available.",
            "Re-run this script after replacing the TODO adapter with the verified API path.",
            "Add the resulting model asset to the iOS Models/ folder and update the runtime loader.",
        ],
    }
    report_path = args.output_dir / "conversion_report.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote conversion report: {report_path}")


if __name__ == "__main__":
    main()

