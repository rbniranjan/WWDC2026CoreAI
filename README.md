# WWDC2026CoreAI

Hands-on Apple Core AI examples using Xcode 27, SwiftUI, and on-device `.aimodel` workflows.

`Swift` `SwiftUI` `Core AI` `Xcode 27 beta` `iOS / iPadOS / Mac Catalyst` `On-device AI`

## Why This Repo Exists

Apple Core AI gives developers a more native path for supported AI models on Apple platforms. This repository explores practical conversion workflows, runtime boundaries, Swift integration patterns, and app architecture for real on-device examples.

This repo is not only sample UI. It documents real conversion problems and solutions, including where model graph boundaries matter and why some postprocessing needs to stay on the Swift side.

## Examples

| Example | Area | Status | What it demonstrates |
| --- | --- | --- | --- |
| [01-CoreAI-PlantDiseaseDetector](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/01-CoreAI-PlantDiseaseDetector/README.md) | Computer Vision / YOLO | Verified foundation | YOLO `.pt` to Core AI `.aimodel`, raw outputs, Swift postprocessing |
| [02-CoreAI-LocalChat](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/02-CoreAI-LocalChat/README.md) | Local Chat / Model Hub | Foundation | SwiftUI chat UI, model catalog, active model selection, local `.aimodel` detection, runtime boundary |

## Verification Matrix

| Area | Example | Result |
| --- | --- | --- |
| Python tests | Example 01 | Passed |
| Core AI conversion | Example 01 | Passed |
| SwiftPM tests | Example 01 | Passed, 4 tests |
| Xcode beta build | Example 01 | Passed |
| SwiftPM tests | Example 02 | Passed |
| Xcode beta build | Example 02 | Passed |

## Repository Layout

| Path | Purpose |
| --- | --- |
| [Examples/01-CoreAI-PlantDiseaseDetector](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/01-CoreAI-PlantDiseaseDetector/README.md) | YOLO plant disease detector conversion plus iOS demo |
| [Examples/02-CoreAI-LocalChat](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/02-CoreAI-LocalChat/README.md) | Swift-only Core AI local chat app foundation |
| [Examples/01-CoreAI-PlantDiseaseDetector/docs](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/01-CoreAI-PlantDiseaseDetector/docs) | Architecture, conversion notes, model contracts, verification |
| [Examples/02-CoreAI-LocalChat/docs](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/02-CoreAI-LocalChat/docs) | Architecture, manifest, manual setup, roadmap, verification |
| [Examples/01-CoreAI-PlantDiseaseDetector/scripts](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/01-CoreAI-PlantDiseaseDetector/scripts) | Local helper scripts for model sync |
| [docs/INDEX.md](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/docs/INDEX.md) | Compact documentation index across examples |

## Start Here

- Explore the YOLO detector example: [Examples/01-CoreAI-PlantDiseaseDetector/README.md](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/01-CoreAI-PlantDiseaseDetector/README.md)
- Explore the local chat app foundation: [Examples/02-CoreAI-LocalChat/README.md](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/02-CoreAI-LocalChat/README.md)
- Review the Core AI YOLO conversion flow: [Examples/01-CoreAI-PlantDiseaseDetector/docs/conversion-notes.md](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/01-CoreAI-PlantDiseaseDetector/docs/conversion-notes.md)
- Review iOS integration and raw detector postprocessing: [Examples/01-CoreAI-PlantDiseaseDetector/docs/ios-integration-notes.md](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/01-CoreAI-PlantDiseaseDetector/docs/ios-integration-notes.md)
- Review local chat architecture and manifest handling: [Examples/02-CoreAI-LocalChat/docs/ARCHITECTURE.md](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/02-CoreAI-LocalChat/docs/ARCHITECTURE.md)
- Review Xcode beta verification notes: [Examples/01-CoreAI-PlantDiseaseDetector/docs/verification-report.md](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/01-CoreAI-PlantDiseaseDetector/docs/verification-report.md), [Examples/02-CoreAI-LocalChat/docs/VERIFICATION.md](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/02-CoreAI-LocalChat/docs/VERIFICATION.md)

## Architecture Snapshot

Example 01:

```text
best.pt
-> convert_to_core_ai.py
-> FarmerHelper_YOLO26_RawDetector.aimodel
-> raw_boxes [1, 4, 2100]
-> raw_scores [1, 38, 2100]
-> DetectionPostProcessor.swift
-> final detections
-> iOS UI overlay
```

Example 02:

```text
model_manifest.json
-> local model detection / remote catalog fallback
-> CoreAIChatRuntime or MockChatRuntime
-> chat UI, model detail, active model selection
```

## Model Artifact Policy

The trained `.pt` models and generated Core AI `.aimodel` assets are intentionally excluded from the repository because they are large/generated artifacts. Generated conversion metadata and copied app-resource `.aimodel` files are also kept local-only.

If you need the model artifacts for testing or review, please open a GitHub issue, comment on the repository, or contact the repository owner. Artifacts can be shared manually when appropriate.

The repository contains the reproducible workflow, docs, model contracts, helper scripts, and app integration code, but not the model binaries themselves.

## Core AI vs Third-party Runtime Note

This repository explores Apple-native Core AI workflows. It does not use `llama.cpp` or other third-party inference runtimes inside these examples.

Core AI conversion still requires understanding supported operations, export boundaries, and runtime contracts. Example 01 demonstrates that directly: the final design exports raw YOLO detector outputs because direct postprocessed YOLO conversion hit an unsupported `aten.remainder.Scalar` path.

Supported or convertible models can be brought into Apple Core AI with the right export and runtime boundary, but not every PyTorch model converts automatically.

## Roadmap

Completed:

- YOLO Core AI conversion
- Swift postprocessing foundation
- local `.aimodel` sync
- Xcode beta build verification
- local chat app foundation

Next:

- polish example UI
- real Core AI LLM runtime experiment
- download manager and remote manifest iteration
- settings UX refinement
- RAG, local embeddings, and document import exploration

## Requirements

- Xcode 27 beta
- Swift 6.4
- Python only for Example 01 conversion scripts
- no Python inside the Swift apps
- Core AI PyTorch Extensions for conversion workflows

## License / Disclaimer

- Model weights follow their own licenses.
- This repository does not redistribute model weights.
- Core AI APIs and tooling may change while in beta.
- These examples are educational and portfolio-oriented demos.
