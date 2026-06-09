# Worktree Plan

## Agent 1: Python YOLO Pipeline

Owns:

```text
python/
models/
docs/model-contract.md
docs/conversion-notes.md
docs/verification-report.md
```

## Agent 2: iOS App

Owns:

```text
ios/
docs/ios-integration-notes.md
```

## Final Integration Only

```text
README.md
root README.md
shared docs
```

## Coordination Rules

- Agents should not edit each other's owned folders.
- Root README and example README should be changed only during final integration unless absolutely necessary.
- The Python agent generates model contract JSON later.
- The iOS agent consumes labels and contract outputs later.
