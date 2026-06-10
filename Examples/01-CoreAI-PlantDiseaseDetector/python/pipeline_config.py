from __future__ import annotations

import importlib
from pathlib import Path
from typing import Any


PYTHON_DIR = Path(__file__).resolve().parent
DEFAULT_MODEL_PATH = (PYTHON_DIR / "../models/raw/best.pt").resolve()
DEFAULT_DATA_YAML = (PYTHON_DIR / "configs/full_plant_data.yaml").resolve()
DEFAULT_EXPORT_CONFIG = (PYTHON_DIR / "configs/export_config.yaml").resolve()
DEFAULT_EXPORTED_DIR = (PYTHON_DIR / "../models/exported").resolve()
DEFAULT_CORE_AI_DIR = (PYTHON_DIR / "../models/core-ai").resolve()
DEFAULT_IOS_PACKAGE_DIR = (PYTHON_DIR / "../models/ios-package").resolve()


def import_yaml_module() -> Any:
    try:
        return importlib.import_module("yaml")
    except ModuleNotFoundError as error:
        raise RuntimeError("pyyaml is required for config file loading") from error


def _coerce_scalar(value: str) -> Any:
    stripped = value.strip()
    if stripped.isdigit():
        return int(stripped)
    try:
        return float(stripped)
    except ValueError:
        return stripped


def _load_simple_yaml_mapping(path: Path) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        key, _, value = line.partition(":")
        if not _:
            raise ValueError(f"Invalid YAML line in {path}: {raw_line}")
        result[key.strip()] = _coerce_scalar(value)
    return result


def resolve_path(path: Path) -> Path:
    return path if path.is_absolute() else (PYTHON_DIR / path).resolve()


def load_export_config(config_path: Path | None = None) -> dict[str, Any]:
    final_path = config_path or DEFAULT_EXPORT_CONFIG
    try:
        yaml = import_yaml_module()
        data = yaml.safe_load(final_path.read_text(encoding="utf-8"))
    except RuntimeError:
        data = _load_simple_yaml_mapping(final_path)
    if not isinstance(data, dict):
        raise ValueError(f"Export config at {final_path} must parse to a mapping")
    return data
