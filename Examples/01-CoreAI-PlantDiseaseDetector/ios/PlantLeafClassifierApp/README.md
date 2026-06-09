# PlantLeafClassifierApp

SwiftUI sample app source for the future plant disease detector demo.

## What Is Included

- A minimal `PlantLeafClassifierApp.xcodeproj` scaffold.
- Placeholder image import and result-view scaffolding.
- Detector-oriented placeholder file names.
- A compile-safe placeholder where verified Apple Core AI integration should be added later.

## Before Building

1. Open the included Xcode project.
2. Set your signing team and, if needed, change `PRODUCT_BUNDLE_IDENTIFIER` from the placeholder value.
3. Confirm your local Xcode/SDK supports the deployment target and APIs used by `PhotosUI`.

## Model Placement

After converting and verifying the Apple-side model asset, place it here:

```text
ios/PlantLeafClassifierApp/PlantLeafClassifierApp/Models/
```

## Core AI Integration Status

- Real Apple Core AI API calls are not included because they were not locally verified in this environment.
- `CoreAIPlantDiseaseDetector` throws a clear unsupported-runtime error until that verification is done.
- Bounding-box detection UI is not implemented yet.
