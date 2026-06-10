import Foundation

struct DetectionPostProcessor {
    func finalize(
        _ detections: [PlantDiseaseDetection],
        confidenceThreshold: Double = 0.35,
        limit: Int = 10
    ) -> [PlantDiseaseDetection] {
        detections
            .filter { $0.confidence >= confidenceThreshold }
            .map { detection in
                let box = DetectionBoundingBox(normalizedRect: detection.boundingBox)
                return PlantDiseaseDetection(
                    id: detection.id,
                    classId: detection.classId,
                    className: detection.className,
                    confidence: detection.confidence,
                    boundingBox: box.normalizedRect
                )
            }
            .sorted { $0.confidence > $1.confidence }
            .prefix(limit)
            .map { $0 }
    }
}

