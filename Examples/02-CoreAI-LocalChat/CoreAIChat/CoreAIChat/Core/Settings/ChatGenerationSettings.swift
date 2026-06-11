import Foundation

struct ChatGenerationSettings: Equatable, Sendable {
    var temperature: Double
    var maxOutputTokens: Int
    var topP: Double

    static let `default` = ChatGenerationSettings(
        temperature: 0.7,
        maxOutputTokens: 512,
        topP: 0.9
    )
}
