# ZooFMProvider Adapter Plan

This document defines the compile-safe boundary for a future `ZooFMProvider` integration in Example 02 without changing the current chat runtime behavior.

## Goal

Add a placeholder adapter boundary in the main app that can compile whether or not `ZooFMProvider` is linked.

Current state:

- `ZooFMProvider` is not part of the main app target graph.
- `MockChatRuntime` remains the default fallback path.
- `ChatRuntimeRouter` is now the live chat boundary and only attempts the external runtime for the Qwen placeholder model.
- The adapter reports availability or an explicit unavailable reason, and only tries generation when the local flag and package are both present.

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
#if ENABLE_ZOO_FM_PROVIDER && canImport(ZooFMProvider)
```

That means:

- current builds without the flag and without the package still compile
- future builds that add both the compile flag and the package can activate the adapter path without renaming the boundary

## Local-Only Enablement Plan

Use a local developer override only. Do not commit these changes.

Recommended approach:

1. keep the shared project and package files unchanged for normal builds
2. add a local Xcode override that appends:

```text
SWIFT_ACTIVE_COMPILATION_CONDITIONS = $(inherited) ENABLE_ZOO_FM_PROVIDER
```

3. add the external package dependency locally only after preparing the patched `coreai-models` checkout
4. keep any local wrapper package reference or user-specific project edits out of git

For SwiftPM-only local experiments, the equivalent compile flag is:

```bash
swift test -Xswiftc -DENABLE_ZOO_FM_PROVIDER
```

That flag alone does not make the module available. The package still needs to be linked in a local-only integration setup.

## Current Adapter Behavior

When `ZooFMProvider` is unavailable:

- adapter returns `.unavailable`
- reason explains whether the compile flag is off or the module is missing
- default builds report that `ENABLE_ZOO_FM_PROVIDER` is not enabled
- flag-enabled builds without the module report that `ZooFMProvider` is still not linked

When `ZooFMProvider` becomes importable in a future spike:

- adapter can return `.available` only when the compile flag is enabled and the local bundle path exists
- missing bundle path or missing local bundle directory returns a clear `.unavailable` reason
- the live chat router can attempt a real `LanguageModelSession` generation for the Qwen placeholder model
- non-Qwen models and default builds remain on the mock path

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

The current live router maps the internal placeholder model ID `qwen-small-q4-placeholder` to this bundle directory when `ENABLE_ZOO_FM_PROVIDER` is enabled.

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
2. keep `ChatRuntimeRouter` as the only live integration point
3. thread adapter availability into model detail or developer settings
4. broaden generation wiring beyond the Qwen placeholder only after the local-only path is proven on hardware
