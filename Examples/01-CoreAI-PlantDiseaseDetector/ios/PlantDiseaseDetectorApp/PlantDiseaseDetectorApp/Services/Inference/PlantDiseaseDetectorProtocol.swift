import UIKit

protocol PlantDiseaseDetectorProtocol {
    var runtimeInfo: ModelRuntimeInfo { get }
    func detect(in image: UIImage) async throws -> [PlantDiseaseDetection]
}

enum PlantDiseaseDetectorError: LocalizedError {
    case missingModelAsset(expectedPath: String)
    case coreAINotVerified
    case invalidImage

    var errorDescription: String? {
        switch self {
        case .missingModelAsset(let expectedPath):
            return "No converted model asset was found in \(expectedPath)."
        case .coreAINotVerified:
            return "Core AI runtime integration is pending Xcode 27 / Core AI SDK verification."
        case .invalidImage:
            return "The selected image could not be processed for detection."
        }
    }
}

