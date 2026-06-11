import Foundation

@MainActor
final class CoreAIChatRuntime: ChatModelRuntime {
    enum RuntimeError: LocalizedError {
        case missingModelFile(String)
        case integrationPending

        var errorDescription: String? {
            switch self {
            case .missingModelFile(let fileName):
                "Model file not found in Resources/AIModels: \(fileName)"
            case .integrationPending:
                "Core AI runtime integration pending"
            }
        }
    }

    private(set) var status: RuntimeStatus = .idle
    private var selectedModel: ModelVariant?
    private var selectedModelURL: URL?

    func load(model: ModelVariant?, localURL: URL?) async {
        guard let model else {
            selectedModel = nil
            selectedModelURL = nil
            status = .unavailable("No active model selected")
            return
        }

        guard let localURL else {
            selectedModel = model
            selectedModelURL = nil
            status = .failed("Model file not found in Resources/AIModels.")
            return
        }

        selectedModel = model
        selectedModelURL = localURL
        status = .unavailable("Core AI runtime integration pending for \(localURL.lastPathComponent)")
    }

    func generateResponse(
        for messages: [ChatMessage],
        settings: ChatGenerationSettings
    ) async throws -> String {
        guard selectedModelURL != nil else {
            throw RuntimeError.missingModelFile(selectedModel?.fileName ?? "unknown .aimodel")
        }

        throw RuntimeError.integrationPending
    }
}
