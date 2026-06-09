# iOS Demo Notes

This folder contains a lightweight SwiftUI scaffold for the future plant disease detector app.

## Opening The Project

1. Open [PlantLeafClassifierApp.xcodeproj](/Users/rniranjan/PersonalProject/WWDC2026CoreAI/Examples/01-CoreAI-PlantDiseaseDetector/ios/PlantLeafClassifierApp/PlantLeafClassifierApp.xcodeproj).
2. Set your Apple development team and preferred bundle identifier.
3. Add the verified model asset under `PlantLeafClassifierApp/Models/` if you have completed Apple-side conversion.
4. Build only after verifying the actual Core AI runtime APIs available in your installed Xcode/SDK.

## Runtime Strategy

- `CoreAIPlantDiseaseDetector.swift` intentionally avoids unverified Apple Core AI symbols.
- `MockPlantDiseaseDetector.swift` remains a placeholder fallback, not a real detector.
- Bounding-box rendering and full detector UI are intentionally deferred to the iOS worktree.
