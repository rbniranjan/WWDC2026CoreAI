import CoreGraphics
import Foundation

struct PlantDiseaseDetection: Identifiable, Hashable {
    let id: UUID
    let classId: Int
    let className: String
    let confidence: Double

    // Normalized bounding box coordinates in the source image's 0...1 space.
    // UI code maps this into the aspect-fit preview rectangle before drawing.
    let boundingBox: CGRect

    init(
        id: UUID = UUID(),
        classId: Int,
        className: String,
        confidence: Double,
        boundingBox: CGRect
    ) {
        self.id = id
        self.classId = classId
        self.className = className
        self.confidence = confidence
        self.boundingBox = boundingBox
    }

    var boundingBoxSummary: String {
        DetectionBoundingBox(normalizedRect: boundingBox).summary
    }
}

