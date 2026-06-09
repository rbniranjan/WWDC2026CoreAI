from __future__ import annotations

import argparse
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate a synthetic leaf dataset.")
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path("data/sample_leaf_dataset"),
        help="Destination directory for the ImageFolder-style dataset.",
    )
    parser.add_argument("--train-count", type=int, default=24, help="Images per class for train split.")
    parser.add_argument("--val-count", type=int, default=8, help="Images per class for validation split.")
    parser.add_argument("--image-size", type=int, default=224, help="Square image size in pixels.")
    parser.add_argument("--seed", type=int, default=7, help="Random seed.")
    return parser.parse_args()


def random_point(rng: random.Random, image_size: int) -> tuple[int, int]:
    return (
        rng.randint(int(image_size * 0.2), int(image_size * 0.8)),
        rng.randint(int(image_size * 0.15), int(image_size * 0.85)),
    )


def draw_leaf(image_size: int, label: str, rng: random.Random) -> Image.Image:
    image = Image.new("RGB", (image_size, image_size), color=(245, 239, 230))
    draw = ImageDraw.Draw(image, "RGBA")

    leaf_color = (55, 150, 75, 255) if label == "healthy" else (120, 95, 45, 255)
    accent_color = (110, 190, 90, 180) if label == "healthy" else (150, 80, 40, 190)
    shadow_color = (30, 60, 30, 80)

    center_x = image_size // 2 + rng.randint(-10, 10)
    center_y = image_size // 2 + rng.randint(-6, 6)
    width = int(image_size * rng.uniform(0.34, 0.5))
    height = int(image_size * rng.uniform(0.58, 0.72))

    leaf_bounds = (
        center_x - width // 2,
        center_y - height // 2,
        center_x + width // 2,
        center_y + height // 2,
    )

    draw.ellipse(leaf_bounds, fill=shadow_color)
    inset = 6
    leaf_bounds = (
        leaf_bounds[0],
        leaf_bounds[1] - inset,
        leaf_bounds[2],
        leaf_bounds[3] - inset,
    )
    draw.ellipse(leaf_bounds, fill=leaf_color)

    vein_points = [
        (center_x, leaf_bounds[1] + 10),
        (center_x + rng.randint(-4, 4), center_y),
        (center_x + rng.randint(-8, 8), leaf_bounds[3] - 12),
    ]
    draw.line(vein_points, fill=(230, 245, 220, 180), width=3)

    for _ in range(6):
        start = (
            center_x + rng.randint(-8, 8),
            rng.randint(leaf_bounds[1] + 16, leaf_bounds[3] - 16),
        )
        delta = rng.randint(20, 34)
        draw.line([start, (start[0] - delta, start[1] - delta // 2)], fill=(235, 245, 225, 110), width=2)
        draw.line([start, (start[0] + delta, start[1] - delta // 2)], fill=(235, 245, 225, 110), width=2)

    if label == "unhealthy":
        for _ in range(rng.randint(4, 8)):
            point = random_point(rng, image_size)
            radius = rng.randint(8, 18)
            draw.ellipse(
                (
                    point[0] - radius,
                    point[1] - radius,
                    point[0] + radius,
                    point[1] + radius,
                ),
                fill=accent_color,
            )
    else:
        for _ in range(rng.randint(2, 4)):
            point = random_point(rng, image_size)
            radius = rng.randint(10, 16)
            draw.ellipse(
                (
                    point[0] - radius,
                    point[1] - radius,
                    point[0] + radius,
                    point[1] + radius,
                ),
                outline=accent_color,
                width=2,
            )

    return image.filter(ImageFilter.SMOOTH)


def write_split(output_dir: Path, split: str, label: str, count: int, image_size: int, rng: random.Random) -> None:
    target_dir = output_dir / split / label
    target_dir.mkdir(parents=True, exist_ok=True)
    for index in range(count):
        image = draw_leaf(image_size=image_size, label=label, rng=rng)
        image.save(target_dir / f"{label}_{index:03d}.png")


def main() -> None:
    args = parse_args()
    rng = random.Random(args.seed)
    output_dir = args.output_dir

    write_split(output_dir, "train", "healthy", args.train_count, args.image_size, rng)
    write_split(output_dir, "train", "unhealthy", args.train_count, args.image_size, rng)
    write_split(output_dir, "val", "healthy", args.val_count, args.image_size, rng)
    write_split(output_dir, "val", "unhealthy", args.val_count, args.image_size, rng)

    print("Synthetic dataset created.")
    print(f"Output: {output_dir}")
    print("Note: these images are only intended for smoke-testing the pipeline.")


if __name__ == "__main__":
    main()

