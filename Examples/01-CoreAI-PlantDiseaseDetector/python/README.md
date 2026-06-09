# Python Notes

This folder still contains the earlier classifier-oriented placeholder scripts.

Current refactor status:

- The intended model for this example is a fine-tuned YOLO detector, expected locally at `../models/raw/best.pt`.
- The real YOLO export/conversion pipeline is not implemented in this base task.
- These files remain in place only as temporary scaffold material for a future Python worktree.

## What Not To Assume Yet

- Do not treat the current scripts as the final detector pipeline.
- Do not commit `best.pt`.
- Do not assume the current Python files represent the final model contract or export flow.

## Planned Direction

- Load `models/raw/best.pt`
- Export an intermediate detector artifact into `../models/exported/`
- Produce a Core AI-ready artifact into `../models/core-ai/` once the Apple SDK path is verified
