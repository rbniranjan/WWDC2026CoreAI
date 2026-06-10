// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PlantDiseaseDetectorCore",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PlantDiseaseDetectorCore",
            targets: ["PlantDiseaseDetectorCore"]
        ),
    ],
    targets: [
        .target(
            name: "PlantDiseaseDetectorCore",
            path: "PlantDiseaseDetectorApp",
            sources: [
                "Models/PlantDiseaseClass.swift",
                "Models/PlantDiseaseDetection.swift",
                "Models/DetectionBoundingBox.swift",
                "Services/Inference/DetectionPostProcessor.swift",
            ]
        ),
        .testTarget(
            name: "PlantDiseaseDetectorCoreTests",
            dependencies: ["PlantDiseaseDetectorCore"],
            path: "Tests/PlantDiseaseDetectorCoreTests"
        ),
    ]
)
