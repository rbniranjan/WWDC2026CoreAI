import CoreGraphics
import Foundation

struct DetectionPostProcessor {
    struct RawDetectorContract: Equatable {
        let inputImageSize: Int
        let classCount: Int
        let anchorCount: Int
        let confidenceThreshold: Double
        let iouThreshold: Double

        static let farmerHelperYOLO26 = RawDetectorContract(
            inputImageSize: 320,
            classCount: 38,
            anchorCount: 2100,
            confidenceThreshold: 0.35,
            iouThreshold: 0.45
        )
    }

    enum PostProcessingError: LocalizedError, Equatable {
        case invalidInputImageSize(Int)
        case labelCountMismatch(expected: Int, actual: Int)
        case labelIDMismatch(expected: Int, actual: Int)
        case rawBoxesCountMismatch(expected: Int, actual: Int)
        case rawScoresCountMismatch(expected: Int, actual: Int)

        var errorDescription: String? {
            switch self {
            case .invalidInputImageSize(let value):
                return "The raw detector contract declared an invalid input image size: \(value)."
            case .labelCountMismatch(let expected, let actual):
                return "The label catalog count (\(actual)) did not match the detector class count (\(expected))."
            case .labelIDMismatch(let expected, let actual):
                return "The label catalog order is invalid. Expected label id \(expected), found \(actual)."
            case .rawBoxesCountMismatch(let expected, let actual):
                return "raw_boxes count mismatch. Expected \(expected) values, found \(actual)."
            case .rawScoresCountMismatch(let expected, let actual):
                return "raw_scores count mismatch. Expected \(expected) values, found \(actual)."
            }
        }
    }

    func detectionsFromRawOutputs(
        rawBoxes: [Float],
        rawScores: [Float],
        labels: [PlantDiseaseClass],
        contract: RawDetectorContract = .farmerHelperYOLO26,
        limit: Int = 10
    ) throws -> [PlantDiseaseDetection] {
        try validate(labels: labels, rawBoxes: rawBoxes, rawScores: rawScores, contract: contract)

        let anchorCount = contract.anchorCount
        let inputSize = Double(contract.inputImageSize)
        let safeLimit = max(limit, 0)
        var candidates: [PlantDiseaseDetection] = []
        candidates.reserveCapacity(min(anchorCount, safeLimit * 3))

        for anchorIndex in 0..<anchorCount {
            let best = bestClass(for: anchorIndex, rawScores: rawScores, classCount: contract.classCount, anchorCount: anchorCount)
            guard best.score >= contract.confidenceThreshold else {
                continue
            }

            let x1 = Double(rawBoxes[anchorIndex])
            let y1 = Double(rawBoxes[anchorCount + anchorIndex])
            let x2 = Double(rawBoxes[(anchorCount * 2) + anchorIndex])
            let y2 = Double(rawBoxes[(anchorCount * 3) + anchorIndex])

            let normalizedRect = normalizedRectFromXYXY(
                x1: x1,
                y1: y1,
                x2: x2,
                y2: y2,
                inputImageSize: inputSize
            )

            guard normalizedRect.width > 0, normalizedRect.height > 0 else {
                continue
            }

            let label = labels[best.classIndex]
            candidates.append(
                PlantDiseaseDetection(
                    classId: label.id,
                    className: label.name,
                    confidence: best.score,
                    boundingBox: normalizedRect
                )
            )
        }

        return finalize(
            candidates,
            confidenceThreshold: contract.confidenceThreshold,
            iouThreshold: contract.iouThreshold,
            limit: safeLimit
        )
    }

    func finalize(
        _ detections: [PlantDiseaseDetection],
        confidenceThreshold: Double = 0.35,
        iouThreshold: Double = 0.45,
        limit: Int = 10
    ) -> [PlantDiseaseDetection] {
        let safeLimit = max(limit, 0)
        let clamped = detections
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

        let reduced = nonMaximumSuppressed(clamped, iouThreshold: iouThreshold)
        return reduced
            .sorted { lhs, rhs in
                if lhs.confidence == rhs.confidence {
                    return lhs.classId < rhs.classId
                }
                return lhs.confidence > rhs.confidence
            }
            .prefix(safeLimit)
            .map { $0 }
    }

    private func validate(
        labels: [PlantDiseaseClass],
        rawBoxes: [Float],
        rawScores: [Float],
        contract: RawDetectorContract
    ) throws {
        guard contract.inputImageSize > 0 else {
            throw PostProcessingError.invalidInputImageSize(contract.inputImageSize)
        }

        guard labels.count == contract.classCount else {
            throw PostProcessingError.labelCountMismatch(expected: contract.classCount, actual: labels.count)
        }

        for (expectedID, label) in labels.enumerated() where label.id != expectedID {
            throw PostProcessingError.labelIDMismatch(expected: expectedID, actual: label.id)
        }

        let expectedBoxes = contract.anchorCount * 4
        guard rawBoxes.count == expectedBoxes else {
            throw PostProcessingError.rawBoxesCountMismatch(expected: expectedBoxes, actual: rawBoxes.count)
        }

        let expectedScores = contract.anchorCount * contract.classCount
        guard rawScores.count == expectedScores else {
            throw PostProcessingError.rawScoresCountMismatch(expected: expectedScores, actual: rawScores.count)
        }
    }

    private func bestClass(
        for anchorIndex: Int,
        rawScores: [Float],
        classCount: Int,
        anchorCount: Int
    ) -> (classIndex: Int, score: Double) {
        var bestClassIndex = 0
        var bestScore = -Double.infinity

        for classIndex in 0..<classCount {
            let offset = (classIndex * anchorCount) + anchorIndex
            let score = Double(rawScores[offset])
            if score > bestScore {
                bestScore = score
                bestClassIndex = classIndex
            }
        }

        return (bestClassIndex, bestScore)
    }

    private func normalizedRectFromXYXY(
        x1: Double,
        y1: Double,
        x2: Double,
        y2: Double,
        inputImageSize: Double
    ) -> CGRect {
        let minX = min(x1, x2) / inputImageSize
        let minY = min(y1, y2) / inputImageSize
        let width = abs(x2 - x1) / inputImageSize
        let height = abs(y2 - y1) / inputImageSize
        return DetectionBoundingBox(
            normalizedRect: CGRect(x: minX, y: minY, width: width, height: height)
        ).normalizedRect
    }

    private func nonMaximumSuppressed(
        _ detections: [PlantDiseaseDetection],
        iouThreshold: Double
    ) -> [PlantDiseaseDetection] {
        guard iouThreshold > 0 else {
            return detections
        }

        let grouped = Dictionary(grouping: detections, by: \.classId)
        var kept: [PlantDiseaseDetection] = []

        for sameClassDetections in grouped.values {
            let sorted = sameClassDetections.sorted { $0.confidence > $1.confidence }
            var accepted: [PlantDiseaseDetection] = []

            for candidate in sorted {
                let overlapsExisting = accepted.contains { existing in
                    intersectionOverUnion(lhs: candidate.boundingBox, rhs: existing.boundingBox) > iouThreshold
                }

                if overlapsExisting == false {
                    accepted.append(candidate)
                }
            }

            kept.append(contentsOf: accepted)
        }

        return kept
    }

    private func intersectionOverUnion(lhs: CGRect, rhs: CGRect) -> Double {
        let intersection = lhs.intersection(rhs)
        guard intersection.isNull == false, intersection.width > 0, intersection.height > 0 else {
            return 0
        }

        let intersectionArea = Double(intersection.width * intersection.height)
        let lhsArea = Double(lhs.width * lhs.height)
        let rhsArea = Double(rhs.width * rhs.height)
        let unionArea = lhsArea + rhsArea - intersectionArea
        guard unionArea > 0 else {
            return 0
        }
        return intersectionArea / unionArea
    }
}
