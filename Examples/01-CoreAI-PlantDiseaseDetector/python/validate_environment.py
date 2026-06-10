from __future__ import annotations

import importlib.util
import importlib
import sys
from dataclasses import dataclass
from pathlib import Path


PYTHON_MIN_VERSION = (3, 10)
PYTHON_DIR = Path(__file__).resolve().parent
DEFAULT_MODEL_PATH = (PYTHON_DIR / "../models/raw/best.pt").resolve()
DEFAULT_DATA_YAML = (PYTHON_DIR / "configs/full_plant_data.yaml").resolve()


@dataclass(frozen=True)
class CheckResult:
    level: str
    label: str
    message: str


def has_module(module_name: str) -> bool:
    try:
        importlib.import_module(module_name)
    except Exception:
        return False
    return True


def check_python_version() -> CheckResult:
    version = sys.version_info[:3]
    if version >= PYTHON_MIN_VERSION:
        return CheckResult("PASS", "python_version", f"Python {version[0]}.{version[1]}.{version[2]}")
    return CheckResult(
        "FAIL",
        "python_version",
        f"Python {version[0]}.{version[1]}.{version[2]} is below the recommended minimum {PYTHON_MIN_VERSION[0]}.{PYTHON_MIN_VERSION[1]}",
    )


def check_import(module_name: str) -> CheckResult:
    if has_module(module_name):
        return CheckResult("PASS", module_name, f"Module '{module_name}' is importable")
    return CheckResult("FAIL", module_name, f"Module '{module_name}' is not importable")


def check_path(path: Path, label: str, missing_level: str, missing_message: str) -> CheckResult:
    if path.exists():
        return CheckResult("PASS", label, f"Found: {path}")
    return CheckResult(missing_level, label, missing_message)


def print_result(result: CheckResult) -> None:
    print(f"[{result.level}] {result.label}: {result.message}")


def main() -> int:
    results = [
        check_python_version(),
        check_import("torch"),
        check_import("ultralytics"),
        check_path(
            DEFAULT_MODEL_PATH,
            "model_path",
            "WARN",
            f"Missing YOLO checkpoint at {DEFAULT_MODEL_PATH}. Place best.pt there before model inspection/export.",
        ),
        check_path(
            DEFAULT_DATA_YAML,
            "data_yaml",
            "FAIL",
            f"Missing dataset config at {DEFAULT_DATA_YAML}",
        ),
    ]

    for result in results:
        print_result(result)

    has_failures = any(result.level == "FAIL" for result in results)
    has_warnings = any(result.level == "WARN" for result in results)

    if has_failures:
        print("Environment validation completed with FAIL status.")
        return 1
    if has_warnings:
        print("Environment validation completed with WARN status.")
        return 0

    print("Environment validation completed with PASS status.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
