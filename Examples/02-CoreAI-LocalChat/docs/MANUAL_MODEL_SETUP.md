# Manual Model Setup

The app supports manual local `.aimodel` detection for development.

1. Build or obtain a local `.aimodel` chat model outside this repository.
2. Copy it into:

```text
Examples/02-CoreAI-LocalChat/CoreAIChat/CoreAIChat/Resources/AIModels/
```

3. Make sure the file name exactly matches a `fileName` entry in:

```text
Examples/02-CoreAI-LocalChat/CoreAIChat/CoreAIChat/Resources/ModelManifest/model_manifest.json
```

4. Open the app, go to Models, and refresh or relaunch.
5. Select a local model and use Set Active Model.
6. Return to Chat. The active-model card will show whether the model is runtime-ready or whether the mock fallback is still being used.

`.aimodel` files are ignored by git. Do not commit model weights, generated model artifacts, build products, DerivedData, or downloaded models.

Downloads are stored separately in the app's Application Support container. Downloaded archives are not extracted in this phase; use the manual folder above when you need a runtime-ready `.aimodel` for local testing.
