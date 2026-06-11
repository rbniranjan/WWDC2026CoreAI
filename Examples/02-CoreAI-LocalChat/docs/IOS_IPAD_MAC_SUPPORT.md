# iPhone, iPad, and Mac Support

CoreAIChat uses SwiftUI and `NavigationSplitView` so the same source can adapt across compact and regular layouts.

The Xcode target is configured for:

- iPhone
- iPad
- Mac Catalyst

The app shell avoids platform-specific runtime assumptions. Future Core AI LLM integration should verify API availability and model behavior separately on each supported platform.
