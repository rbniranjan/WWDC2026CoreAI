# Qwen3.5 0.8B Runner Contract

Date checked: 2026-06-11
Xcode checked: `/Applications/Xcode-beta.app`
Note: the previously referenced path `/Users/rniranjan/Downloads/Xcode-beta.app/Contents/Developer` does not exist on this machine. The audit used the installed beta at `/Applications/Xcode-beta.app/Contents/Developer`.
Bundle checked: `CoreAIChat/CoreAIChat/Resources/AIModels/qwen3_5_0_8b_decode_int8hu_perchan_sym/`

## Local bundle facts

Verified local bundle contents:

- `metadata.json`
- `qwen3_5_0_8b_decode_int8hu_perchan_sym.aimodel/`
- `tokenizer/`
- `tokenizer/tokenizer.json`
- `tokenizer/chat_template.jinja`
- `tokenizer/tokenizer_config.json`
- `tokenizer/special_tokens_map.json`

Verified `metadata.json` facts:

- `kind = "llm"`
- `assets.main = "qwen3_5_0_8b_decode_int8hu_perchan_sym.aimodel"`
- `language.embedded_tokenizer = true`
- `language.function_map.main = ["main"]`
- `source.hf_model_id = "Qwen/Qwen3.5-0.8B"`

## Hugging Face README contract

README source:

- [mlboydaisuke/qwen3.5-0.8B-CoreAI](https://huggingface.co/mlboydaisuke/qwen3.5-0.8B-CoreAI)

Documented app path in the README:

- `LanguageBundle`
- `EngineFactory.createEngine`
- set `COREAI_CHUNK_THRESHOLD=1`
- do not call `warmup()`

Documented lower-level path in the README:

- Python `AIModel.load(...)`
- `load_function("main")`
- tokenizer from the upstream Qwen repository

## APIs found in the installed SDK

Confirmed by compiler probes against the iPhoneOS 27 SDK:

- `AIModel(contentsOf: URL)` compiles through `import CoreAI`
- `AIModel(resolvingBookmark: Data)` compiles through `import CoreAI`
- `AIModel.loadFunction(named:)` compiles through `import CoreAI`
- `InferenceFunction.run(inputs: ...)` is present on the lower-level runtime surface
- `InferenceFunctionDescriptor.inputNames`
- `InferenceFunctionDescriptor.stateNames`
- `InferenceFunctionDescriptor.outputNames`

## APIs missing from the installed SDK

Not found anywhere in the installed Xcode 27 beta SDK:

- `LanguageBundle`
- `EngineFactory`
- `EngineFactory.createEngine`
- a public Apple tokenizer or chat-template API that this app can call

Also observed:

- `CoreAI.framework` is not present in the iPhone Simulator SDK, so simulator builds cannot import `CoreAI`
- `import CoreAI` fails for an iPhone Simulator target with `no such module 'CoreAI'`
- exported symbols mention `AIModel.loadFunctionState(named:)`, but that member is not callable from the public `import CoreAI` surface on this machine
- `CoreAI.swiftinterface` is only a thin re-export surface and does not publish `LanguageBundle` or `EngineFactory`

## Exact blocker

Real end-to-end generation does not work in this spike.

The blocker is not bundle discovery. The blocker is the public SDK surface:

1. The README says apps should use `LanguageBundle` and `EngineFactory.createEngine`
2. Those app-level APIs are not present in the installed Xcode 27 beta SDK, even for the iPhoneOS device SDK
3. The lower-level `AIModel` load path exists on the device SDK, but this app still lacks a public Apple tokenizer/chat-template surface for prompt -> `input_ids`
4. Simulator verification cannot exercise `CoreAI` at all because the simulator SDK does not ship the framework

This means the blocker is not "simulator only". It is a combination of:

- simulator: framework absent
- device SDK: lower-level `AIModel` APIs present
- current beta public app surface: documented `LanguageBundle` / `EngineFactory.createEngine` path still missing

## What the spike now does

- keeps adapter-based runner selection
- verifies the Qwen bundle structure and metadata
- reports the missing public app APIs in preflight
- on generation attempt, emits diagnostics and stops with a clear runtime blocker error
- never fakes a generated answer

## Next steps

1. Re-check a newer Xcode / OS beta for public `LanguageBundle` and `EngineFactory.createEngine`
2. Re-check for a public Apple tokenizer/chat-template API usable from Swift
3. Once those appear, replace the current blocker path with:
   - load bundle
   - create engine
   - apply `COREAI_CHUNK_THRESHOLD=1`
   - send one-token warmup by generation, not `warmup()`
   - wire short text prompt -> response for Qwen only
4. Until then, keep the current runner behavior:
   - preflight reports `language_bundle_api_missing`
   - preflight reports `tokenizer_api_missing`
   - generation attempt ends with `runtimeAPINotAvailable`
