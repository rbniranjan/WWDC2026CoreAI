from __future__ import annotations

import importlib
from pathlib import Path
from typing import Any


def _coerce_scalar(value: str) -> Any:
    stripped = value.strip()
    if stripped.isdigit():
        return int(stripped)
    return stripped


def _load_simple_yaml_mapping(yaml_path: Path) -> dict[str, Any]:
    result: dict[str, Any] = {}
    current_mapping_key: str | None = None
    nested_mapping: dict[Any, Any] = {}

    for raw_line in yaml_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.rstrip()
        if not line or line.lstrip().startswith("#"):
            continue

        if line.startswith("  "):
            if current_mapping_key is None:
                raise ValueError("Unexpected indented YAML entry without a parent key")
            key, _, value = line.strip().partition(":")
            if not _:
                raise ValueError(f"Invalid nested YAML line: {line}")
            nested_mapping[_coerce_scalar(key)] = value.strip()
            continue

        if current_mapping_key is not None:
            result[current_mapping_key] = nested_mapping
            current_mapping_key = None
            nested_mapping = {}

        key, _, value = line.partition(":")
        if not _:
            raise ValueError(f"Invalid YAML line: {line}")
        key = key.strip()
        value = value.strip()
        if value == "":
            current_mapping_key = key
            nested_mapping = {}
        else:
            result[key] = _coerce_scalar(value)

    if current_mapping_key is not None:
        result[current_mapping_key] = nested_mapping

    return result


def _normalize_name_mapping(names: Any) -> dict[int, str]:
    if isinstance(names, list):
        return {index: str(value) for index, value in enumerate(names)}

    if isinstance(names, dict):
        normalized: dict[int, str] = {}
        for raw_key, raw_value in names.items():
            try:
                key = int(raw_key)
            except (TypeError, ValueError) as error:
                raise ValueError(f"Invalid class index {raw_key!r}; expected integer-like keys") from error
            normalized[key] = str(raw_value)
        return normalized

    raise ValueError("Expected 'names' to be a list or dict")


def _validate_continuous_indices(mapping: dict[int, str]) -> None:
    expected_indices = list(range(len(mapping)))
    actual_indices = sorted(mapping)
    if actual_indices != expected_indices:
        raise ValueError(
            f"Class indices must be continuous starting at 0; expected {expected_indices}, got {actual_indices}"
        )


def load_class_names(yaml_path: Path) -> list[str]:
    try:
        yaml = importlib.import_module("yaml")
        data = yaml.safe_load(yaml_path.read_text(encoding="utf-8"))
    except ModuleNotFoundError as error:
        data = _load_simple_yaml_mapping(yaml_path)
    if not isinstance(data, dict):
        raise ValueError("Dataset YAML must parse to a mapping")

    if "names" not in data:
        raise ValueError("Dataset YAML is missing required 'names' field")

    mapping = _normalize_name_mapping(data["names"])
    _validate_continuous_indices(mapping)

    class_names = [mapping[index] for index in range(len(mapping))]
    expected_nc = data.get("nc")
    if expected_nc is not None and int(expected_nc) != len(class_names):
        raise ValueError(f"'nc' value {expected_nc} does not match the number of names {len(class_names)}")

    return class_names


def names_value_to_list(names: Any) -> list[str]:
    mapping = _normalize_name_mapping(names)
    _validate_continuous_indices(mapping)
    return [mapping[index] for index in range(len(mapping))]
