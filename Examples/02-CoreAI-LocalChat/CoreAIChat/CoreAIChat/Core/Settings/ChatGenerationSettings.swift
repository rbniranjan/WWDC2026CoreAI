import Foundation

struct ChatGenerationSettings: Codable, Equatable, Sendable {
    var contextWindow: Int
    var temperature: Double
    var maxOutputTokens: Int
    var topP: Double

    static let `default` = ChatGenerationSettings(
        contextWindow: 2_048,
        temperature: 0.7,
        maxOutputTokens: 512,
        topP: 0.9
    )

    func validated() -> ChatGenerationSettings {
        ChatGenerationSettings(
            contextWindow: max(256, min(contextWindow, 131_072)),
            temperature: max(0, min(temperature, 2)),
            maxOutputTokens: max(1, min(maxOutputTokens, 16_384)),
            topP: max(0.01, min(topP, 1))
        )
    }
}
