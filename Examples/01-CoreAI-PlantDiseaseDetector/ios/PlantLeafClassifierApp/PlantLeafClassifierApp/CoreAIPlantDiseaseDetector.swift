import Foundation
import UIKit

enum PlantDiseaseDetectorRuntime: String {
    case coreAI = "Core AI"
    case mockFallback = "Mock fallback"
}

struct PlantDiseasePrediction: Equatable {
    let label: String
    let confidence: Double
    let runtime: PlantDiseaseDetectorRuntime
}

enum PlantDiseaseDetectorError: LocalizedError {
    case missingModelAsset
    case coreAINotVerified

    var errorDescription: String? {
        switch self {
        case .missingModelAsset:
            return "No converted detector model asset was found in the app bundle Models directory."
        case .coreAINotVerified:
            return "Core AI runtime integration is pending local SDK verification in this environment."
        }
    }
}

protocol PlantDiseaseDetectorProtocol {
    func predict(image: UIImage) async throws -> PlantDiseasePrediction
}

struct CoreAIPlantDiseaseDetector: PlantDiseaseDetectorProtocol {
    func predict(image: UIImage) async throws -> PlantDiseasePrediction {
        guard Bundle.main.urls(forResourcesWithExtension: nil, subdirectory: "Models")?.isEmpty == false else {
            throw PlantDiseaseDetectorError.missingModelAsset
        }

        // TODO(Core AI SDK verification):
        // Replace this placeholder with verified Apple Core AI runtime calls once
        // the exact Xcode/Core AI symbols are confirmed locally.
        throw PlantDiseaseDetectorError.coreAINotVerified
    }
}
