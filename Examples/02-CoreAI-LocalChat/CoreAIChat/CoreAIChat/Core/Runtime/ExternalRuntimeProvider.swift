import Foundation

struct ExternalRuntimeContext: Equatable {
    var modelID: String?
    var modelName: String?
    var bundleURL: URL?

    init(modelID: String? = nil, modelName: String? = nil, bundleURL: URL? = nil) {
        self.modelID = modelID
        self.modelName = modelName
        self.bundleURL = bundleURL
    }
}

enum ExternalRuntimeProviderError: LocalizedError, Equatable {
    case unavailable(String)
    case missingPrompt
    case generationFailed(String)

    var errorDescription: String? {
        switch self {
        case .unavailable(let reason):
            reason
        case .missingPrompt:
            "No user prompt was provided for the external runtime."
        case .generationFailed(let reason):
            reason
        }
    }
}

@MainActor
protocol ExternalRuntimeProvider {
    var providerID: String { get }
    var displayName: String { get }

    func availability(for context: ExternalRuntimeContext) -> ExternalRuntimeAvailability
    func generateResponse(
        for messages: [ChatMessage],
        settings: ChatGenerationSettings,
        context: ExternalRuntimeContext
    ) async throws -> String
}

extension ExternalRuntimeProvider {
    func generateResponse(
        for messages: [ChatMessage],
        settings: ChatGenerationSettings,
        context: ExternalRuntimeContext
    ) async throws -> String {
        throw ExternalRuntimeProviderError.unavailable(
            availability(for: context).summary
        )
    }
}
