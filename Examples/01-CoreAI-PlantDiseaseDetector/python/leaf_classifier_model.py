from __future__ import annotations

from dataclasses import dataclass

import torch
from torch import nn


DEFAULT_IMAGE_SIZE = 224
DEFAULT_MEAN = (0.485, 0.456, 0.406)
DEFAULT_STD = (0.229, 0.224, 0.225)
CLASS_NAMES = ["healthy", "unhealthy"]


@dataclass(frozen=True)
class ModelConfig:
    image_size: int = DEFAULT_IMAGE_SIZE
    num_classes: int = len(CLASS_NAMES)
    dropout: float = 0.15


class SmallLeafClassifier(nn.Module):
    """A compact CNN intended for smoke-test scale experiments."""

    def __init__(self, config: ModelConfig | None = None) -> None:
        super().__init__()
        self.config = config or ModelConfig()
        self.features = nn.Sequential(
            nn.Conv2d(3, 16, kernel_size=3, stride=2, padding=1),
            nn.BatchNorm2d(16),
            nn.ReLU(inplace=True),
            nn.Conv2d(16, 32, kernel_size=3, stride=2, padding=1),
            nn.BatchNorm2d(32),
            nn.ReLU(inplace=True),
            nn.Conv2d(32, 64, kernel_size=3, stride=2, padding=1),
            nn.BatchNorm2d(64),
            nn.ReLU(inplace=True),
            nn.Conv2d(64, 96, kernel_size=3, stride=2, padding=1),
            nn.BatchNorm2d(96),
            nn.ReLU(inplace=True),
            nn.AdaptiveAvgPool2d((1, 1)),
        )
        self.classifier = nn.Sequential(
            nn.Flatten(),
            nn.Dropout(p=self.config.dropout),
            nn.Linear(96, self.config.num_classes),
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        x = self.features(x)
        return self.classifier(x)


def build_model(image_size: int = DEFAULT_IMAGE_SIZE) -> SmallLeafClassifier:
    return SmallLeafClassifier(ModelConfig(image_size=image_size))

