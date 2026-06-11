import Foundation

@MainActor
protocol ChatModelRuntime: AnyObject {
    var status: RuntimeStatus { get }

    func load(model: ModelVariant?, localURL: URL?) async
    func generateResponse(
        for messages: [ChatMessage],
        settings: ChatGenerationSettings
    ) async throws -> String
}
