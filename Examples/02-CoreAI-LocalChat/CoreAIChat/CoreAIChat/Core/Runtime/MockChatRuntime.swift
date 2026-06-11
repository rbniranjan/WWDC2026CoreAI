import Foundation

@MainActor
final class MockChatRuntime: ChatModelRuntime {
    enum MockError: Error {
        case missingPrompt
    }

    private(set) var status: RuntimeStatus = .idle
    private var loadedModel: ModelVariant?

    func load(model: ModelVariant?, localURL: URL?) async {
        loadedModel = model
        if let model {
            status = .ready("\(model.name) mock")
        } else {
            status = .ready("Mock runtime")
        }
    }

    func generateResponse(
        for messages: [ChatMessage],
        settings: ChatGenerationSettings
    ) async throws -> String {
        guard let prompt = messages.last(where: { $0.role == .user })?.content.trimmingCharacters(in: .whitespacesAndNewlines),
              !prompt.isEmpty else {
            throw MockError.missingPrompt
        }

        status = .generating
        defer {
            if let loadedModel {
                status = .ready("\(loadedModel.name) mock")
            } else {
                status = .ready("Mock runtime")
            }
        }

        let modelName = loadedModel?.name ?? "mock runtime"
        let summary = prompt.count > 90 ? String(prompt.prefix(87)) + "..." : prompt

        return """
        I am running with \(modelName). Phase 1 uses a mock generator, so this response is local demo text.

        You wrote: "\(summary)"

        Once the Core AI LLM generation API is wired in, this same chat flow can route the selected `.aimodel` through `ChatModelRuntime`.
        """
    }
}
