# External Core AI Runtime Integration Plan

This note evaluates the Swift runtime pieces from [`john-rocky/coreai-model-zoo`](https://github.com/john-rocky/coreai-model-zoo) for possible use in Example 02 without replacing the existing app architecture.

## Recommendation

Use `ZooFMProvider` as the preferred external runtime path for future Qwen3.5-0.8B integration. Do not adopt `CoreAIRunner` as the primary path.

Keep the current `ChatModelRuntime` abstraction and the runner registry. If we proceed, add a new runner implementation that wraps `ZooLanguageModel` behind the existing runtime boundary.

## Why `ZooFMProvider`

`ZooFMProvider` is the only upstream Swift runtime path in the reference repo that is explicitly documented as verified for Qwen3.5-0.8B on Xcode 27 beta. It is library code, not app UI, and it already encapsulates:

- `LanguageBundle(at:)`
- `CoreAIRunner(from: bundle)`
- `makeInferenceEngine()`
- tokenizer loading through the Apple-side runtime package
- prompt rendering and tool-call formatting for Qwen-style chat
- `COREAI_CHUNK_THRESHOLD=1` setup called out in the upstream README

It fits our architecture if we keep it behind a new adapter runner in our registry instead of letting it leak into SwiftUI or view models.

## Why Not `CoreAIRunner`

`CoreAIRunner` is still a draft spike.

Observed blockers from the upstream package:

- `swift/README.md` marks it as draft and not yet compiled.
- `HybridCoreAIEngine.swift` is explicitly annotated as written against the exact Apple Core AI API shape but not yet verified.
- The implementation is low-level and greedy-only.
- It depends on details such as manual `NDArray` state allocation, direct function execution, and tokenizer/sampling work that we would still need to own.

That is useful as reference material, but it is not the smallest integration path for our app.

## Exact Dependency Strategy

Recommended strategy for the next implementation phase:

1. Keep the current app and tests unchanged for simulator builds.
2. Add a new optional runner file in our app, for example `ZooFMChatRuntime.swift`, that conforms to our existing `ChatModelRuntime`.
3. Gate that runner behind a local compile flag such as `ENABLE_ZOO_FM_PROVIDER` and environments where the Apple runtime stack is available.
4. Use `ZooFMProvider` as the external runtime layer, not the upstream app code.
5. Keep `MockChatRuntime` as the fallback for simulator and unsupported targets.

## Packages And Files Needed

The upstream package is not directly consumable as a normal remote SwiftPM dependency today.

Needed components:

- `john-rocky/coreai-model-zoo/swift/Sources/ZooFMProvider`
- `john-rocky/coreai-model-zoo/swift/README.md`
- `john-rocky/coreai-model-zoo/knowledge/swift-runtime.md`
- Apple `coreai-models/swift` package
- the upstream patch set referenced by `swift/README.md`:
  - `apps/coreai-shared-product.patch`
  - `apps/coreai-pipelined-extra-states.patch`
  - `apps/coreai-pipelined-per-token-inputs.patch`
  - `apps/coreai-pipelined-static-inputs.patch`

Apple-side frameworks and modules used by `ZooFMProvider`:

- `CoreAI`
- `CoreAILanguageModels`
- `FoundationModels`
- `Tokenizers`
- `Synchronization`

## Practical Blockers

`ZooFMProvider` is feasible, but not plug-and-play.

Current blockers:

- The upstream `swift/Package.swift` depends on `../coreai-models` as a local path package.
- The upstream README states the Apple `coreai-models` checkout must be patched locally before the package builds for hybrid bundles such as Qwen3.5.
- The upstream verification note is for macOS 27 beta. That is materially better than `CoreAIRunner`, but it does not give us a ready simulator path for our existing app build lane.
- Our current Example 02 verification path is iPhone simulator, and simulator builds cannot exercise the real Core AI runtime stack.

## Phase 3C Spike Result

An isolated build spike was created at [ExternalRuntimeSpike](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/02-CoreAI-LocalChat/ExternalRuntimeSpike) and mirrored into a temporary harness outside the repo for compilation.

Observed result:

- `ZooFMProvider` built successfully with Xcode 27 beta after supplying a sibling Apple `coreai-models` checkout and applying the four upstream patches.
- The patched Apple checkout used for the probe was `a270998`.
- The compile path is therefore viable.

Exact files used in the isolated spike:

- [Package.swift](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/02-CoreAI-LocalChat/ExternalRuntimeSpike/Package.swift)
- [README.md](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/02-CoreAI-LocalChat/ExternalRuntimeSpike/README.md)
- [PromptRenderer.swift](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/02-CoreAI-LocalChat/ExternalRuntimeSpike/Sources/ZooFMProvider/PromptRenderer.swift)
- [StreamTagParser.swift](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/02-CoreAI-LocalChat/ExternalRuntimeSpike/Sources/ZooFMProvider/StreamTagParser.swift)
- [ZooExecutor.swift](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/02-CoreAI-LocalChat/ExternalRuntimeSpike/Sources/ZooFMProvider/ZooExecutor.swift)
- [ZooLanguageModel.swift](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/02-CoreAI-LocalChat/ExternalRuntimeSpike/Sources/ZooFMProvider/ZooLanguageModel.swift)
- [coreai-model-zoo-BSD-3-Clause.txt](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/02-CoreAI-LocalChat/ExternalRuntimeSpike/ThirdPartyLicenses/coreai-model-zoo-BSD-3-Clause.txt)

Direct dependency requirements confirmed by the spike:

- sibling `../coreai-models` checkout
- upstream patch stack:
  - `coreai-shared-product.patch`
  - `coreai-pipelined-extra-states.patch`
  - `coreai-pipelined-per-token-inputs.patch`
  - `coreai-pipelined-static-inputs.patch`

Transitive SwiftPM dependencies observed during the successful build:

- `swift-transformers`
- `swift-huggingface`
- `swift-jinja`
- `xgrammar`
- `yyjson`
- `EventSource`
- `swift-nio`
- `swift-crypto`
- `swift-collections`
- `swift-atomics`
- `swift-system`
- `swift-asn1`

Updated blocker assessment:

- The blocker is not compilation.
- The blocker is adoption cost and packaging shape: the runtime currently depends on a patched local Apple checkout and a broad transitive package graph that we should not pull directly into the Example 02 app target graph yet.

## Default Build Policy

Normal shared builds must continue to work without `ZooFMProvider`.

Current policy:

- do not add `ZooFMProvider` to the default Example 02 target graph
- do not require a patched `coreai-models` checkout for default builds
- gate any future adapter wiring behind a local compile condition such as `ENABLE_ZOO_FM_PROVIDER`
- keep the default app runtime on the existing mock and placeholder paths until a local developer intentionally enables the external runtime

## Minimal Integration Shape For Our App

The smallest acceptable integration would be:

1. Keep `CoreAIChatRuntime` and `CoreAIModelRunnerRegistry`.
2. Add one new runner case selected by `runtime.adapter`.
3. Inside that runner, bridge our prompt/request model to a `ZooLanguageModel` session.
4. Convert the runtime response back into our existing chat message/result type.
5. Keep all UI, model-list, settings, and fallback behavior unchanged.

This avoids importing external runtime assumptions into the rest of the app.

## License And Attribution

The upstream repo is BSD 3-Clause licensed.

Implications:

- We may use, modify, and redistribute the source.
- If we copy or vendor source later, we must retain the copyright notice, license conditions, and disclaimer.
- If we redistribute binaries containing that code, the same notice and disclaimer need to appear in accompanying materials.
- We must not imply endorsement by the upstream author.

The upstream LICENSE also notes that parts of the conversion code derive from Apple `coreai-models` code under BSD 3-Clause terms. If we later vendor code, we need to preserve those notices as well.

Suggested attribution text:

> This project evaluates runtime integration patterns from `john-rocky/coreai-model-zoo` (BSD 3-Clause). Any future vendored source must retain the upstream copyright notice, license terms, and disclaimer.

## Next Implementation Step

Do not vendor code yet.

Next step:

1. Create a small isolated branch or local spike target that attempts to compile only `ZooFMProvider` plus the required Apple `coreai-models` dependency stack on a device-capable Xcode 27 environment.
2. If that compiles, add a thin adapter runner behind our existing registry.
3. Keep simulator builds on `MockChatRuntime` until a device-only runtime path is proven.
