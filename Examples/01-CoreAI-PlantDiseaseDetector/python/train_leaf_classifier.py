from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

import torch
from torch import nn
from torch.utils.data import DataLoader
from torchvision import datasets, transforms
from tqdm import tqdm

from leaf_classifier_model import CLASS_NAMES, DEFAULT_MEAN, DEFAULT_STD, build_model


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Train the synthetic leaf classifier.")
    parser.add_argument("--dataset-dir", type=Path, required=True, help="Path to the ImageFolder dataset root.")
    parser.add_argument("--epochs", type=int, default=3, help="Number of training epochs.")
    parser.add_argument("--batch-size", type=int, default=8, help="Batch size.")
    parser.add_argument("--lr", type=float, default=1e-3, help="Learning rate.")
    parser.add_argument("--image-size", type=int, default=224, help="Square resize dimension.")
    parser.add_argument("--output-dir", type=Path, default=Path("models"), help="Directory for training outputs.")
    parser.add_argument(
        "--sample-run",
        action="store_true",
        help="Limit batches to keep the run small for smoke tests.",
    )
    return parser.parse_args()


def make_dataloaders(dataset_dir: Path, image_size: int, batch_size: int) -> tuple[DataLoader[Any], DataLoader[Any], list[str]]:
    train_dir = dataset_dir / "train"
    val_dir = dataset_dir / "val"
    if not train_dir.exists() or not val_dir.exists():
        raise FileNotFoundError("Expected train/ and val/ directories under the dataset root.")

    common_transform = transforms.Compose(
        [
            transforms.Resize((image_size, image_size)),
            transforms.ToTensor(),
            transforms.Normalize(mean=DEFAULT_MEAN, std=DEFAULT_STD),
        ]
    )

    train_dataset = datasets.ImageFolder(train_dir, transform=common_transform)
    val_dataset = datasets.ImageFolder(val_dir, transform=common_transform)

    train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True)
    val_loader = DataLoader(val_dataset, batch_size=batch_size, shuffle=False)
    return train_loader, val_loader, train_dataset.classes


def run_epoch(
    model: nn.Module,
    loader: DataLoader[Any],
    criterion: nn.Module,
    optimizer: torch.optim.Optimizer | None,
    device: torch.device,
    sample_run: bool,
) -> tuple[float, float]:
    training = optimizer is not None
    model.train(training)
    total_loss = 0.0
    total_correct = 0
    total_examples = 0

    for step, (inputs, targets) in enumerate(tqdm(loader, leave=False, desc="train" if training else "val")):
        inputs = inputs.to(device)
        targets = targets.to(device)

        if training:
            optimizer.zero_grad(set_to_none=True)

        with torch.set_grad_enabled(training):
            logits = model(inputs)
            loss = criterion(logits, targets)
            if training:
                loss.backward()
                optimizer.step()

        predictions = logits.argmax(dim=1)
        total_loss += loss.item() * inputs.size(0)
        total_correct += (predictions == targets).sum().item()
        total_examples += inputs.size(0)

        if sample_run and step >= 2:
            break

    average_loss = total_loss / max(total_examples, 1)
    accuracy = total_correct / max(total_examples, 1)
    return average_loss, accuracy


def save_artifacts(
    output_dir: Path,
    model: nn.Module,
    class_names: list[str],
    metrics: dict[str, Any],
    image_size: int,
) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    checkpoint_path = output_dir / "leaf_classifier.pt"
    torch.save(
        {
            "state_dict": model.state_dict(),
            "class_names": class_names,
            "image_size": image_size,
            "normalization": {"mean": DEFAULT_MEAN, "std": DEFAULT_STD},
        },
        checkpoint_path,
    )

    example_input = torch.randn(1, 3, image_size, image_size)
    scripted_model = torch.jit.trace(model.cpu(), example_input)
    scripted_model.save(str(output_dir / "leaf_classifier_torchscript.pt"))

    class_mapping = {
        "index_to_class": {str(index): name for index, name in enumerate(class_names)},
        "class_to_index": {name: index for index, name in enumerate(class_names)},
        "unknown_class": "unknown_or_low_confidence",
    }
    (output_dir / "class_mapping.json").write_text(json.dumps(class_mapping, indent=2) + "\n", encoding="utf-8")
    (output_dir / "training_metrics.json").write_text(json.dumps(metrics, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    args = parse_args()
    train_loader, val_loader, class_names = make_dataloaders(args.dataset_dir, args.image_size, args.batch_size)

    if class_names != CLASS_NAMES:
        print(f"Dataset class order: {class_names}")
        print(f"Expected order: {CLASS_NAMES}")

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model = build_model(image_size=args.image_size).to(device)
    criterion = nn.CrossEntropyLoss()
    optimizer = torch.optim.Adam(model.parameters(), lr=args.lr)

    history: list[dict[str, float]] = []
    for epoch in range(1, args.epochs + 1):
        train_loss, train_acc = run_epoch(model, train_loader, criterion, optimizer, device, args.sample_run)
        val_loss, val_acc = run_epoch(model, val_loader, criterion, None, device, args.sample_run)
        epoch_result = {
            "epoch": epoch,
            "train_loss": train_loss,
            "train_accuracy": train_acc,
            "val_loss": val_loss,
            "val_accuracy": val_acc,
        }
        history.append(epoch_result)
        print(
            f"Epoch {epoch}/{args.epochs} "
            f"train_loss={train_loss:.4f} train_acc={train_acc:.3f} "
            f"val_loss={val_loss:.4f} val_acc={val_acc:.3f}"
        )

    metrics = {
        "sample_run": args.sample_run,
        "dataset_dir": str(args.dataset_dir),
        "epochs": args.epochs,
        "batch_size": args.batch_size,
        "learning_rate": args.lr,
        "image_size": args.image_size,
        "class_names": class_names,
        "history": history,
        "best_val_accuracy": max((entry["val_accuracy"] for entry in history), default=0.0),
        "device": str(device),
    }
    save_artifacts(args.output_dir, model.eval(), class_names, metrics, args.image_size)

    final = history[-1]
    print(f"Validation loss: {final['val_loss']:.4f}")
    print(f"Validation accuracy: {final['val_accuracy']:.3f}")
    print(f"Saved outputs to: {args.output_dir}")


if __name__ == "__main__":
    main()

