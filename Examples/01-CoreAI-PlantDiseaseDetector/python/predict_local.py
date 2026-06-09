from __future__ import annotations

import argparse
from pathlib import Path

import torch
from PIL import Image
from torchvision import transforms

from leaf_classifier_model import DEFAULT_MEAN, DEFAULT_STD, build_model


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run local inference on one image.")
    parser.add_argument("--model-path", type=Path, required=True, help="Path to the trained checkpoint.")
    parser.add_argument("--image-path", type=Path, required=True, help="Path to an input image.")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    if not args.model_path.exists():
        raise FileNotFoundError(f"Model not found: {args.model_path}")
    if not args.image_path.exists():
        raise FileNotFoundError(f"Image not found: {args.image_path}")

    checkpoint = torch.load(args.model_path, map_location="cpu")
    image_size = int(checkpoint.get("image_size", 224))
    class_names = checkpoint["class_names"]

    model = build_model(image_size=image_size)
    model.load_state_dict(checkpoint["state_dict"])
    model.eval()

    transform = transforms.Compose(
        [
            transforms.Resize((image_size, image_size)),
            transforms.ToTensor(),
            transforms.Normalize(mean=DEFAULT_MEAN, std=DEFAULT_STD),
        ]
    )

    image = Image.open(args.image_path).convert("RGB")
    input_tensor = transform(image).unsqueeze(0)

    with torch.no_grad():
        logits = model(input_tensor)
        probabilities = torch.softmax(logits, dim=1)

    confidence, index = torch.max(probabilities, dim=1)
    predicted_class = class_names[index.item()]
    print(f"Predicted class: {predicted_class}")
    print(f"Confidence: {confidence.item():.2%}")


if __name__ == "__main__":
    main()

