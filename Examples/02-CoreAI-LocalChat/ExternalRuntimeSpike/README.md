# ExternalRuntimeSpike

This folder isolates a minimum `ZooFMProvider` packaging spike for Example 02. It is not wired into the main app.

Contents:

- a minimal `Package.swift`
- upstream `ZooFMProvider` Swift sources only
- preserved upstream BSD 3-Clause license text

Not included:

- `apps/CoreAIChat`
- model bundles
- `CoreAIRunner`
- app integration code
- cloned Apple `coreai-models`

Build intent:

1. Keep the spike outside the main app target graph.
2. Probe whether the upstream `ZooFMProvider` source can build in isolation with Xcode 27 beta.
3. Capture the exact dependency and patch requirements before touching `CoreAIChat`.

Expected dependency shape:

- sibling checkout: `../coreai-models`
- upstream patch stack applied to that checkout:
  - `coreai-shared-product.patch`
  - `coreai-pipelined-extra-states.patch`
  - `coreai-pipelined-per-token-inputs.patch`
  - `coreai-pipelined-static-inputs.patch`

Source provenance:

- `Sources/ZooFMProvider/*` copied from `john-rocky/coreai-model-zoo`
- license text preserved in `ThirdPartyLicenses/coreai-model-zoo-BSD-3-Clause.txt`

Phase 3C result:

- The isolated package built successfully with `DEVELOPER_DIR="/Applications/Xcode-beta.app/Contents/Developer" swift build` in a temporary harness.
- The build required a sibling `coreai-models` checkout plus the documented four-patch stack.
- The patched Apple checkout used for the probe was `a270998`.
- The build pulled the full transitive dependency graph from `coreai-models`, including `swift-transformers`, `swift-huggingface`, `swift-jinja`, `xgrammar`, `yyjson`, `EventSource`, `swift-nio`, `swift-crypto`, `swift-collections`, `swift-atomics`, `swift-system`, and `swift-asn1`.

Current blocker:

- There is no compile blocker once the patched dependency stack exists.
- The real constraint is packaging and integration cost: the runtime depends on a patched local Apple checkout and a large transitive SwiftPM graph, so it should remain outside the main app target graph until a dedicated adapter path is proven.
