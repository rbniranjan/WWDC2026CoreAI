import Foundation
import UIKit

struct CoreAIPlantDiseaseDetector: PlantDiseaseDetectorProtocol {
    private let resourceLoader: ModelResourceLoader

    init(resourceLoader: ModelResourceLoader = ModelResourceLoader()) {
        self.resourceLoader = resourceLoader
    }

    var runtimeInfo: ModelRuntimeInfo {
        let assetURL = resourceLoader.primaryModelAssetURL()
        return ModelRuntimeInfo(
            mode: .coreAI,
            detail: assetURL == nil
                ? "No model asset detected yet. The app will fall back to mock detections."
                : "Model asset found, but real Core AI runtime wiring remains TODO.",
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
        // Replace this placeholder with verified Apple Core AI runtime calls once
        // the exact Xcode 27 / Core AI symbols are confirmed locally.
        // The Python/model agent will later provide the converted model asset
        // and a matching exported contract for detector outputs.
        throw PlantDiseaseDetectorError.coreAINotVerified
    }
}
