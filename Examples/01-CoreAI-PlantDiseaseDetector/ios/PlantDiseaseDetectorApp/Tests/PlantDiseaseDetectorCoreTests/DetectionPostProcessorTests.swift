import CoreGraphics
import XCTest

@testable import PlantDiseaseDetectorCore

final class DetectionPostProcessorTests: XCTestCase {
    func testConvertsRawOutputsIntoNormalizedDetections() throws {
        let contract = DetectionPostProcessor.RawDetectorContract(
            inputImageSize: 320,
            classCount: 3,
            anchorCount: 4,
            confidenceThreshold: 0.35,
            iouThreshold: 0.45
        )
        let labels = [
            PlantDiseaseClass(id: 0, name: "Healthy"),
            PlantDiseaseClass(id: 1, name: "Rust"),
            PlantDiseaseClass(id: 2, name: "Scab"),
        ]
        let rawBoxes: [Float] = [
            10, 100, 0, 200,
            20, 120, 0, 220,
            90, 210, 0, 280,
            140, 260, 0, 300,
        ]
        let rawScores: [Float] = [
            0.12, 0.11, 0.10, 0.09,
            0.20, 0.42, 0.19, 0.18,
            0.15, 0.88, 0.08, 0.22,
        ]

        let detections = try DetectionPostProcessor().detectionsFromRawOutputs(
            rawBoxes: rawBoxes,
            rawScores: rawScores,
            labels: labels,
            contract: contract,
            limit: 10
        )

        XCTAssertEqual(detections.count, 1)
        XCTAssertEqual(detections[0].classId, 2)
        XCTAssertEqual(detections[0].className, "Scab")
        XCTAssertEqual(detections[0].confidence, 0.88, accuracy: 0.0001)
        XCTAssertEqual(detections[0].boundingBox.origin.x, 0.3125, accuracy: 0.0001)
        XCTAssertEqual(detections[0].boundingBox.origin.y, 0.375, accuracy: 0.0001)
        XCTAssertEqual(detections[0].boundingBox.width, 0.34375, accuracy: 0.0001)
        XCTAssertEqual(detections[0].boundingBox.height, 0.4375, accuracy: 0.0001)
    }

    func testRejectsTensorShapeMismatch() {
        let contract = DetectionPostProcessor.RawDetectorContract(
            inputImageSize: 320,
            classCount: 2,
            anchorCount: 3,
            confidenceThreshold: 0.35,
            iouThreshold: 0.45
        )
        let labels = [
            PlantDiseaseClass(id: 0, name: "Healthy"),
            PlantDiseaseClass(id: 1, name: "Scab"),
        ]

        XCTAssertThrowsError(
            try DetectionPostProcessor().detectionsFromRawOutputs(
                rawBoxes: Array(repeating: 0, count: 11),
                rawScores: Array(repeating: 0, count: 6),
                labels: labels,
                contract: contract
            )
        ) { error in
            XCTAssertEqual(
                error as? DetectionPostProcessor.PostProcessingError,
                .rawBoxesCountMismatch(expected: 12, actual: 11)
            )
        }
    }

    func testRejectsNonSequentialLabelIDs() {
        let contract = DetectionPostProcessor.RawDetectorContract(
            inputImageSize: 320,
            classCount: 2,
            anchorCount: 1,
            confidenceThreshold: 0.35,
            iouThreshold: 0.45
        )
        let labels = [
            PlantDiseaseClass(id: 0, name: "Healthy"),
            PlantDiseaseClass(id: 7, name: "Scab"),
        ]

        XCTAssertThrowsError(
            try DetectionPostProcessor().detectionsFromRawOutputs(
                rawBoxes: Array(repeating: 0, count: 4),
                rawScores: Array(repeating: 0, count: 2),
                labels: labels,
                contract: contract
            )
        ) { error in
            XCTAssertEqual(
                error as? DetectionPostProcessor.PostProcessingError,
                .labelIDMismatch(expected: 1, actual: 7)
            )
        }
    }

    func testClassAwareNMSKeepsDifferentClasses() {
        let detections = [
            PlantDiseaseDetection(
                classId: 0,
                className: "Healthy",
                confidence: 0.91,
                boundingBox: CGRect(x: 0.10, y: 0.10, width: 0.40, height: 0.40)
            ),
            PlantDiseaseDetection(
                classId: 0,
                className: "Healthy",
                confidence: 0.72,
                boundingBox: CGRect(x: 0.12, y: 0.12, width: 0.38, height: 0.38)
            ),
            PlantDiseaseDetection(
                classId: 1,
                className: "Scab",
                confidence: 0.86,
                boundingBox: CGRect(x: 0.11, y: 0.11, width: 0.39, height: 0.39)
            ),
        ]

        let reduced = DetectionPostProcessor().finalize(
            detections,
            confidenceThreshold: 0.35,
            iouThreshold: 0.45,
            limit: 10
        )

        XCTAssertEqual(reduced.count, 2)
        XCTAssertEqual(reduced.map(\.classId), [0, 1])
        let confidences = reduced.map(\.confidence)
        XCTAssertEqual(confidences.count, 2)
        XCTAssertEqual(confidences[0], 0.91, accuracy: 0.0001)
        XCTAssertEqual(confidences[1], 0.86, accuracy: 0.0001)
    }
}
