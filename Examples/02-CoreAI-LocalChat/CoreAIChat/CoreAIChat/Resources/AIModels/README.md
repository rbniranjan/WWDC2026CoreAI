# Local `.aimodel` Files

This folder is for manual local testing only.

- `.aimodel` files are intentionally not committed to this repository.
- Copy local `.aimodel` files into this folder when testing on your machine.
- File names must match `Resources/ModelManifest/model_manifest.json`.
- The app detects local files and lets you select a usable manifest entry.
- Downloaded artifacts are stored in Application Support, not in this resource folder.
- Downloaded archives are not extracted into runtime-ready `.aimodel` files in this phase.

Example:

```text
Resources/AIModels/local-demo-core-ai.aimodel
```
