# Core AI Runner Files - Manual Integration Notes

These files are intended for the CoreAIChat example:

```text
Examples/02-CoreAI-LocalChat/CoreAIChat/CoreAIChat/Core/Runtime/
```

## Files

### 1. CoreAIRunnerArchitecture.swift

Step 1: generic runtime architecture.

Adds:

- `CoreAIModelRunner`
- `CoreAIModelRunnerRegistry`
- `CoreAIGenerationRequest`
- `CoreAIGenerationEvent`
- `CoreAIResolvedArtifact`
- `CoreAIRunnerPreflightResult`
- safe fallback runners:
  - `CoreAIAdapterRequiredRunner`
  - `CoreAIUnsupportedRunner`
  - `CoreAIMockExternalCatalogRunner`

This file is meant to compile without real Core AI LLM APIs.

### 2. CoreAIConcreteRunnerSkeletons.swift

Step 2 scaffold: known adapter-specific runners.

Adds compile-safe placeholder runners for:

- `coreaiPipelinedNStateText`
- `coreaiPipelinedExtraStateText`
- `gemma4MultiStagePipelinedText`
- `coreaiPipelinedVisionLanguage`
- `coreaiStandardLanguageModel`

These runners preflight model profiles and local artifacts, but do **not** implement real generation yet.

## Required existing file

These files depend on:

```text
CoreAIExternalModelCatalog.swift
```

Specifically these model/catalog types:

- `CoreAIExternalModelProfile`
- `CoreAIRuntimeAdapter`
- `CoreAIRuntimeStatus`
- `CoreAIArtifactRole`
- `CoreAIComputePreference`

## Suggested usage

```swift
let registry = CoreAIModelRunnerRegistry.knownExternalModelRegistry()

let result = registry.preflight(
    profile: selectedExternalModelProfile,
    localArtifacts: resolvedArtifacts
)

if result.canGenerate {
    let stream = registry.generate(
        request: CoreAIGenerationRequest(
            model: selectedExternalModelProfile,
            messages: [
                CoreAIChatTurn(role: .user, content: "Hello")
            ],
            localArtifacts: resolvedArtifacts
        )
    )
}
```

## Important

These files intentionally avoid fake Core AI runtime calls.

Real generation should be implemented only after you verify, for one selected model:

- exact artifact layout
- tokenizer files
- chat template
- Core AI function names
- input names
- output names
- state/cache names
- decode loop contract
- sampling/stop-token behavior

Recommended first real target:

```text
Qwen3.5 0.8B Core AI
```

or:

```text
Granite 350M / 1B Core AI
```
