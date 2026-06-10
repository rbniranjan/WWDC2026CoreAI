from __future__ import annotations

from pathlib import Path

import pytest

from plant_disease_labels import load_class_names


def write_yaml(path: Path, contents: str) -> None:
    path.write_text(contents, encoding="utf-8")


def test_load_class_names_from_dict_names(tmp_path: Path) -> None:
    yaml_path = tmp_path / "labels.yaml"
    write_yaml(
        yaml_path,
        "nc: 2\nnames:\n  0: Apple___Apple_scab\n  1: Apple___Black_rot\n",
    )

    assert load_class_names(yaml_path) == ["Apple___Apple_scab", "Apple___Black_rot"]


def test_load_class_names_from_list_names(tmp_path: Path) -> None:
    yaml_path = tmp_path / "labels.yaml"
    write_yaml(
        yaml_path,
        "nc: 2\nnames:\n  - Healthy\n  - Unhealthy\n",
    )

    assert load_class_names(yaml_path) == ["Healthy", "Unhealthy"]


def test_rejects_non_continuous_indices(tmp_path: Path) -> None:
    yaml_path = tmp_path / "labels.yaml"
    write_yaml(
        yaml_path,
        "nc: 2\nnames:\n  0: first\n  2: third\n",
    )

    with pytest.raises(ValueError, match="continuous"):
        load_class_names(yaml_path)


def test_rejects_mismatched_nc(tmp_path: Path) -> None:
    yaml_path = tmp_path / "labels.yaml"
    write_yaml(
        yaml_path,
        "nc: 3\nnames:\n  0: first\n  1: second\n",
    )

    with pytest.raises(ValueError, match="does not match"):
        load_class_names(yaml_path)

