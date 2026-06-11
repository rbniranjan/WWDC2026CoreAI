# WWDC2026CoreAI

Apple-native Core AI examples for Swift apps, model conversion workflows, and on-device runtime boundaries.

This repository explores practical Core AI development on Apple platforms. The examples focus on SwiftUI apps, `.aimodel` integration, model contracts, conversion limits, and clean boundaries between model artifacts and application code.

## Examples

| Example | Area | Current state | Start here |
| --- | --- | --- | --- |
| `01-CoreAI-PlantDiseaseDetector` | Computer vision | Verified Core AI conversion and Swift postprocessing path | [Example 01 README](Examples/01-CoreAI-PlantDiseaseDetector/README.md) |
| `02-CoreAI-LocalChat` | Local chat app foundation | SwiftUI chat shell, model catalog, settings, download foundation, mock runtime | [Example 02 README](Examples/02-CoreAI-LocalChat/README.md) |

## Verification Matrix

| Check | Example 01 | Example 02 |
| --- | --- | --- |
| Swift app builds with Xcode beta | Passed | Passed |
| SwiftPM tests | Passed | Passed |
| Core AI artifact workflow | YOLO raw detector conversion documented | Runtime boundary documented, no LLM artifact committed |
| Model artifact policy | Artifacts excluded | Artifacts excluded |
| Third-party inference runtime | Not used in app runtime | Not used |

## Repository Layout

```text
Examples/
  01-CoreAI-PlantDiseaseDetector/
    docs/
    python/
    swift/
  02-CoreAI-LocalChat/
    CoreAIChat/
    docs/
    scripts/
docs/
  INDEX.md
```

## Start Here

- Build the local chat app: [Examples/02-CoreAI-LocalChat/README.md](Examples/02-CoreAI-LocalChat/README.md)
- Review the local chat architecture: [Examples/02-CoreAI-LocalChat/docs/ARCHITECTURE.md](Examples/02-CoreAI-LocalChat/docs/ARCHITECTURE.md)
- Review the model manifest contract: [Examples/02-CoreAI-LocalChat/docs/MODEL_MANIFEST.md](Examples/02-CoreAI-LocalChat/docs/MODEL_MANIFEST.md)
- Review the plant detector flow: [Examples/01-CoreAI-PlantDiseaseDetector/README.md](Examples/01-CoreAI-PlantDiseaseDetector/README.md)
- Browse the documentation index: [docs/INDEX.md](docs/INDEX.md)

## Model Artifact Policy

Model files are intentionally excluded from this repository.

Do not commit:

- `.aimodel` files
- `.pt`, `.bin`, `.gguf`, `.safetensors`, or other model weights
- downloaded model artifacts
- generated conversion metadata
- DerivedData, `.build`, or `.swiftpm`

The repository contains source code, manifests, tests, scripts, and documentation needed to understand or reproduce the workflows. Model artifacts can be shared separately when licensing and review context allow.

## Core AI And Runtime Boundaries

This repo explores Apple-native Core AI workflows. It does not use `llama.cpp` or third-party inference runtimes inside the Swift apps.

Core AI model work is not only a file-format change. Model graph support, tokenizer behavior, postprocessing, runtime inputs and outputs, and platform availability all matter. Example 01 keeps YOLO postprocessing in Swift because the practical runtime boundary is the raw detector output. Example 02 keeps `CoreAIChatRuntime` as a compile-safe boundary and uses `MockChatRuntime` until a compatible Core AI LLM artifact and runtime API path are available.

Not every PyTorch model converts automatically. Unsupported operators, dynamic graph behavior, tokenizer/runtime coupling, and licensing restrictions must be handled explicitly.

## Requirements

- Xcode 27 beta
- Swift 6.4
- iOS/iPadOS simulator SDK from the Xcode beta
- Python only for Example 01 conversion tooling
- No Python inside the Swift apps

Use the Xcode beta with inline `DEVELOPER_DIR`:

```bash
DEVELOPER_DIR="/Users/rniranjan/Downloads/Xcode-beta.app/Contents/Developer" xcodebuild -version
```

Do not change the default Xcode with `xcode-select -s`.

## Roadmap

- Continue polishing SwiftUI app surfaces for iPhone, iPad, and Mac Catalyst.
- Add more Core AI conversion notes where runtime boundaries are meaningful.
- Explore real Core AI LLM generation only when a compatible artifact and API path are available.
- Add archive extraction and compatibility validation for downloaded chat artifacts.
- Explore RAG, embeddings, and document import in a later phase.

## Disclaimer

Core AI APIs and Xcode beta behavior may change. Model licenses remain attached to the original model providers. This repository does not redistribute model weights and does not claim that every model is suitable for conversion, redistribution, or on-device use.
