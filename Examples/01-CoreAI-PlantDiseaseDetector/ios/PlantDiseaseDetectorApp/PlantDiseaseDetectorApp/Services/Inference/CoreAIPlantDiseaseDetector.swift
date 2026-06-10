import Foundation
import UIKit

struct CoreAIPlantDiseaseDetector: PlantDiseaseDetectorProtocol {
    private let resourceLoader: ModelResourceLoader

    init(resourceLoader: ModelResourceLoader = ModelResourceLoader()) {
        self.resourceLoader = resourceLoader
    }

    var runtimeInfo: ModelRuntimeInfo {
        let assetURL = resourceLoader.primaryModelAssetURL()
        let contract = resourceLoader.loadModelContract()
        return ModelRuntimeInfo(
            mode: .coreAI,
            detail: assetURL == nil
                ? "No model asset detected yet. The app will fall back to mock detections."
                : contract == nil
                    ? "Model asset found, but the bundled raw detector contract is missing or unreadable."
                    : "Model asset found. Swift raw-output postprocessing is ready, but verified Core AI runtime wiring remains TODO.",
            modelSearchPath: "Resources/AIModels/",
            modelAssetAvailable: assetURL != nil
        )
    }

    func detect(in image: UIImage) async throws -> [PlantDiseaseDetection] {
        guard image.cgImage != nil else {
            throw PlantDiseaseDetectorError.invalidImage
        }

        guard resourceLoader.primaryModelAssetURL() != nil else {
            throw PlantDiseaseDetectorError.missingModelAsset(expectedPath: "Resources/AIModels/")
        }

        // TODO(Core AI SDK verification):
        // 1. Load the local .aimodel from Resources/AIModels/.
        // 2. Invoke the verified Core AI entrypoint with image -> raw_boxes/raw_scores.
        // 3. Feed those raw tensors into DetectionPostProcessor.detectionsFromRawOutputs(...)
        //    using the bundled label catalog and contract thresholds.
        throw PlantDiseaseDetectorError.coreAINotVerified
    }
}
