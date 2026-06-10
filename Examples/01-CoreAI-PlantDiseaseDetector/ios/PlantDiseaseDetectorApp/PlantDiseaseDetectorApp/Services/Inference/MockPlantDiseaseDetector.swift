import CoreGraphics
import Foundation
import UIKit

struct MockPlantDiseaseDetector: PlantDiseaseDetectorProtocol {
    private let resourceLoader: ModelResourceLoader
    private let imagePreprocessor: ImagePreprocessor
    private let postProcessor: DetectionPostProcessor

    init(
        resourceLoader: ModelResourceLoader = ModelResourceLoader(),
        imagePreprocessor: ImagePreprocessor = ImagePreprocessor(),
        postProcessor: DetectionPostProcessor = DetectionPostProcessor()
    ) {
        self.resourceLoader = resourceLoader
        self.imagePreprocessor = imagePreprocessor
        self.postProcessor = postProcessor
    }

    var runtimeInfo: ModelRuntimeInfo {
        .mockFallbackReady
    }

    func detect(in image: UIImage) async throws -> [PlantDiseaseDetection] {
        guard image.cgImage != nil else {
            throw PlantDiseaseDetectorError.invalidImage
        }

        let labels = resourceLoader.loadLabels()
        let metrics = imagePreprocessor.colorSignature(for: image)
        let primaryIndex = min(Int((metrics.green * 10).rounded()) % max(labels.count, 1), max(labels.count - 1, 0))
        let secondaryIndex = min((primaryIndex + 2) % max(labels.count, 1), max(labels.count - 1, 0))

        let primaryClass = labels[primaryIndex]
        let secondaryClass = labels[secondaryIndex]
        let primaryConfidence = min(max(0.58 + Double(metrics.green - metrics.red * 0.35), 0.58), 0.94)
        let secondaryConfidence = min(max(0.38 + Double(metrics.contrast * 0.4), 0.38), 0.79)

        let detections = [
            PlantDiseaseDetection(
                classId: primaryClass.id,
                className: primaryClass.name,
                confidence: primaryConfidence,
                boundingBox: CGRect(x: 0.14, y: 0.18, width: 0.46, height: 0.34)
            ),
            PlantDiseaseDetection(
                classId: secondaryClass.id,
                className: secondaryClass.name,
                confidence: secondaryConfidence,
                boundingBox: CGRect(x: 0.54, y: 0.44, width: 0.24, height: 0.22)
            ),
        ]

        return postProcessor.finalize(detections, confidenceThreshold: 0.35)
    }
}
