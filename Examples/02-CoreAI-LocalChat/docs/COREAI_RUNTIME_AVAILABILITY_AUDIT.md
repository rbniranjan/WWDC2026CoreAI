# Core AI Runtime Availability Audit

Date: 2026-06-11
Repo: `WWDC2026CoreAI`
Target: `Examples/02-CoreAI-LocalChat/CoreAIChat`
Audit scope: Xcode beta SDK/runtime availability only. No generation implementation.

## Xcode beta used

Requested path in task:

- `/Users/rniranjan/Downloads/Xcode-beta.app/Contents/Developer`

Actual installed beta used for this audit:

- `/Applications/Xcode-beta.app/Contents/Developer`

The requested `Downloads` path does not exist on this machine. Default Xcode was not changed. `xcode-select -p` still points at:

- `/Applications/Xcode.app/Contents/Developer`

## SDK paths

Using the installed beta:

- iPhone Simulator SDK:
  - `/Applications/Xcode-beta.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator27.0.sdk`
- iPhoneOS device SDK:
  - `/Applications/Xcode-beta.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS27.0.sdk`

## Framework availability

### iPhone Simulator SDK

`CoreAI.framework` is missing.

Observed by path check:

- no `.../iPhoneSimulator27.0.sdk/System/Library/Frameworks/CoreAI.framework`

Observed by compiler probe:

- `import CoreAI` for an iPhone Simulator target fails with:
  - `error: no such module 'CoreAI'`

Conclusion:

- simulator builds cannot use `CoreAI`

### iPhoneOS device SDK

`CoreAI.framework` is present.

Observed paths:

- `/Applications/Xcode-beta.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks/CoreAI.framework`
- `/Applications/Xcode-beta.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS27.0.sdk/System/Library/Frameworks/CoreAI.framework`

Module files present:

- `CoreAI.tbd`
- `Modules/CoreAI.swiftmodule/arm64e-apple-ios.swiftinterface`
- `Modules/CoreAI.swiftmodule/arm64e-apple-ios.swiftdoc`

Conclusion:

- device builds can import `CoreAI`

## Public Swift import surface

The public `CoreAI.swiftinterface` is minimal. It only re-exports `CoreAIDelegates` and does not itself declare the higher-level app APIs mentioned in the Qwen README.

Compiler probes against the iPhoneOS 27 SDK confirm:

- available:
  - `AIModel(contentsOf: URL)`
  - `AIModel(resolvingBookmark: Data)`
  - `AIModel.loadFunction(named:)`
  - `InferenceFunctionDescriptor.inputNames`
  - `InferenceFunctionDescriptor.stateNames`
  - `InferenceFunctionDescriptor.outputNames`
- exported in `CoreAI.tbd` but not callable through the public `import CoreAI` surface:
  - `AIModel.loadFunctionState(named:)`

## Symbols and types checked

### Found

- `AIModel`
- `AIModel.init(contentsOf:...)`
- `AIModel.init(compiledContentsOf:...)` in the export table
- `AIModel.loadFunction(named:)`
- `InferenceFunction`
- `InferenceFunction.run(inputs:...)`
- `InferenceFunctionDescriptor`

### Missing from the current public SDK surface

- `LanguageBundle`
- `EngineFactory`
- `EngineFactory.createEngine`
- any obvious public Apple tokenizer API for this runtime
- any obvious public Apple chat-template API for this runtime

Searches across `/Applications/Xcode-beta.app/Contents/Developer` did not find `LanguageBundle`, `EngineFactory`, or `createEngine` associated with Core AI.

## Qwen README contract checked

README source:

- [mlboydaisuke/qwen3.5-0.8B-CoreAI](https://huggingface.co/mlboydaisuke/qwen3.5-0.8B-CoreAI)

Documented app path in the README:

- load the bundle via `LanguageBundle`
- create the engine via `EngineFactory.createEngine`
- set `COREAI_CHUNK_THRESHOLD=1` before engine creation
- do not call `warmup()`

Documented lower-level path in the README:

- Python `AIModel.load(...)`
- `load_function("main")`
- tokenizer from upstream `Qwen/Qwen3.5-0.8B`

## Current project blocker behavior

Current runner behavior in `CoreAIConcreteRunnerSkeletons.swift`:

- preflight reports device/simulator availability distinctions
- preflight emits:
  - `language_bundle_api_missing`
  - `tokenizer_api_missing`
- generation attempt does not fake output
- generation stops with:
  - `CoreAIModelRunnerError.runtimeAPINotAvailable`

## Can Qwen real generation proceed now?

No.

Reason:

1. Simulator path is blocked because `CoreAI.framework` is absent there
2. Device SDK exposes lower-level `AIModel` loading and function execution surfaces
3. The documented app-level Swift path from the README, `LanguageBundle` + `EngineFactory.createEngine`, is still missing from the installed Xcode beta
4. The current public SDK also does not expose an Apple tokenizer/chat-template surface for prompt -> `input_ids`

So the blocker is not simulator-only. It is:

- simulator: framework missing
- device SDK: low-level APIs partly available
- current public app surface: still incomplete for the documented Qwen integration path

## Recommended next step

1. Keep the current compile-safe blocker behavior in the runner
2. Re-audit a newer Xcode / OS beta for:
   - `LanguageBundle`
   - `EngineFactory.createEngine`
   - a public tokenizer/chat-template API
3. Only after those appear should the app attempt the README-style Qwen path
