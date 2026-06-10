import Foundation

enum DetectorRuntimeMode: String, Codable {
    case coreAI = "Core AI"
    case mockFallback = "Mock fallback"
}

struct ModelRuntimeInfo: Equatable {
    let mode: DetectorRuntimeMode
    let detail: String
    let modelSearchPath: String
    let modelAssetAvailable: Bool

    static let coreAIUnavailable = ModelRuntimeInfo(
        mode: .coreAI,
        detail: "Awaiting a verified Core AI model asset and runtime implementation.",
        modelSearchPath: "Resources/AIModels/",
        modelAssetAvailable: false
    )

    static let mockFallbackReady = ModelRuntimeInfo(
        mode: .mockFallback,
        detail: "Mock detector is ready and uses deterministic sample detections.",
        modelSearchPath: "Resources/AIModels/",
        modelAssetAvailable: false
    )

    func withDetail(_ detail: String) -> ModelRuntimeInfo {
        ModelRuntimeInfo(
            mode: mode,
            detail: detail,
            modelSearchPath: modelSearchPath,
            modelAssetAvailable: modelAssetAvailable
        )
    }
}

