# Verification

Use the Xcode beta with inline `DEVELOPER_DIR`.

From `Examples/02-CoreAI-LocalChat`:

```bash
./scripts/verify-xcode-beta-build.sh
```

The script checks:

- Xcode path and version.
- Swift package tests.
- Xcode project build for the app target.

Do not run `xcode-select -s`.
