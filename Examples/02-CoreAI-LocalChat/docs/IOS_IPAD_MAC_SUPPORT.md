# iPhone, iPad, and Mac Support

CoreAIChat uses SwiftUI and `NavigationSplitView` so the same source can adapt across compact and regular layouts.

The Xcode target is configured for:

- iPhone
- iPad
- Mac Catalyst

The app shell avoids platform-specific runtime assumptions. Future Core AI LLM integration should verify API availability and model behavior separately on each supported platform.

## Layout Notes

- Chat uses a compact active-model card, prompt chips, and bounded message bubbles.
- Models use scrollable card rows instead of a dense table so compact widths remain readable.
- Model details use an adaptive metadata grid.
- Settings use grouped cards rather than platform-specific screens.

The app does not duplicate feature logic per platform.
