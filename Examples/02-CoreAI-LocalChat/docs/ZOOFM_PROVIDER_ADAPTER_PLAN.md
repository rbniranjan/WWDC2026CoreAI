# ZooFMProvider Adapter Plan

This document defines the compile-safe boundary for a future `ZooFMProvider` integration in Example 02 without changing the current chat runtime behavior.

## Goal

Add a placeholder adapter boundary in the main app that can compile whether or not `ZooFMProvider` is linked.

Current state:

- `ZooFMProvider` is not part of the main app target graph.
- `MockChatRuntime` and the existing runner registry remain the live behavior.
- The adapter only reports availability or an explicit unavailable reason.

## Added Boundary Types

Main app runtime placeholders:

- `ExternalRuntimeAvailability`
- `ExternalRuntimeProvider`
- `ZooFMProviderAdapter`

Design intent:

- keep the boundary independent from SwiftUI
- compile safely with or without the external package
- avoid changing `ChatModelRuntime` until the dependency path is acceptable

## Compile Strategy

`ZooFMProviderAdapter` is guarded by:

```swift
#if canImport(ZooFMProvider)
```

That means:

- current builds without the package still compile
- future builds that add the package can activate the adapter path without renaming the boundary

## Current Adapter Behavior

When `ZooFMProvider` is unavailable:

- adapter returns `.unavailable`
- reason explains that the package is not linked into `CoreAIChat`
- reason also calls out the patched `coreai-models` prerequisite

When `ZooFMProvider` becomes importable in a future spike:

- adapter can return `.available`
- no chat-generation wiring happens yet
- the adapter remains a boundary object until a later phase integrates it into runner selection

## Future Wiring

### 1. Package dependency

Do not add the package directly to the main app until we accept the dependency shape.

Future options:

- local Swift package reference to a curated wrapper target
- vendored package target kept separate from the app target by default
- explicit build setting or compilation condition to turn it on for developer builds only

### 2. Patched `coreai-models` checkout

The external runtime requires a sibling Apple checkout with patches applied, matching the verified spike:

- sibling checkout: `../coreai-models`
- required patches:
  - `coreai-shared-product.patch`
  - `coreai-pipelined-extra-states.patch`
  - `coreai-pipelined-per-token-inputs.patch`
  - `coreai-pipelined-static-inputs.patch`

### 3. License notices

If we later vendor or copy source into the main app path:

- preserve the BSD 3-Clause notice from `john-rocky/coreai-model-zoo`
- preserve any Apple-derived BSD notices carried by copied files
- document attribution in the repo docs and any distributed binary materials as needed

### 4. Qwen local bundle path

The first supported local-bundle candidate should remain:

```text
Examples/02-CoreAI-LocalChat/CoreAIChat/CoreAIChat/Resources/AIModels/qwen3_5_0_8b_decode_int8hu_perchan_sym/
```

Expected bundle contents:

- `metadata.json`
- `qwen3_5_0_8b_decode_int8hu_perchan_sym.aimodel/`
- `tokenizer/`

### 5. App settings/runtime toggle

Do not auto-enable the external runtime.

Future wiring should add a developer-facing runtime selection control, for example:

- `Mock`
- `Core AI Placeholder`
- `ZooFMProvider (Experimental)`

Requirements for that toggle:

- off by default
- only shown when the adapter reports `.available`
- selected runtime still flows through the existing runner registry and chat runtime boundary

## Next Step

After the package/dependency policy is accepted:

1. add the external package in a disabled-by-default integration path
2. map `runtime.adapter` values to the placeholder adapter
3. thread adapter availability into model detail or developer settings
4. only then consider generation wiring for the Qwen local bundle
