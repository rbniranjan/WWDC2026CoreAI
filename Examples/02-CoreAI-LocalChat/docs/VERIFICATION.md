# Verification

Use the Xcode beta with inline `DEVELOPER_DIR`.

From `Examples/02-CoreAI-LocalChat`:

```bash
./scripts/verify-xcode-beta-build.sh
```

The script checks:

- Xcode path and version.
- Swift package tests using `/tmp/coreai-chat-swiftpm-build`.
- Xcode project build for the app target.
- DerivedData outside the repository.

Do not run `xcode-select -s`.

Additional manual checks for Phase 2B:

```bash
plutil -lint CoreAIChat/CoreAIChat/Info.plist
python3 -m json.tool CoreAIChat/CoreAIChat/Resources/ModelManifest/model_manifest.json >/tmp/coreai-chat-manifest.json
git check-ignore -v CoreAIChat/CoreAIChat/Resources/AIModels/LocalDemoModel.aimodel
```

The final check should confirm `.aimodel` files are ignored while `Resources/AIModels/README.md` remains trackable.

Expected toolchain on the current local setup:

- Xcode 27.0
- Build version 27A5194q
- Swift 6.4
